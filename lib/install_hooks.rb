module Pod
  class Installer
    alias my_run_podfile_post_install_hook run_podfile_post_install_hook
    def run_podfile_post_install_hook
      flutter_post_install(self) if defined?(flutter_post_install)
      my_run_podfile_post_install_hook
      # 配置子工程依赖的查找路径
      aggregate_target = aggregate_targets[0]
      pod_target_subprojects.each do |pod_subproject|
        pod_subproject.native_targets.each do |target|
          if defined?(flutter_post_install)
            resolve_flutter_dependency target,
                                                  aggregate_target.user_project.root_object.name
          end
        end
      end
    end

    def resolve_flutter_dependency(target, root_project_name)
      return unless target.platform_name == :ios

      # [target.deployment_target] is a [String] formatted as "8.0".
      inherit_deployment_target = target.deployment_target[/\d+/].to_i < 11

      # flutter_root ---> ~/.flutter_sdks/3.7.0
      # Add search paths from $flutter_root/bin/cache/artifacts/engine.
      artifacts_dir = File.join("bin", "cache", "artifacts", "engine")
      debug_framework_dir = File.expand_path(File.join(artifacts_dir, "ios", "Flutter.xcframework"),
                                             flutter_root)

      unless Dir.exist?(debug_framework_dir)
        # iOS artifacts have not been downloaded.
        raise "#{debug_framework_dir} must exist. If you're running pod install manually, make sure \"flutter precache --ios\" is executed first"
      end

      release_framework_dir = File.expand_path(File.join(artifacts_dir, "ios-release", "Flutter.xcframework"),
                                               flutter_root)

      # Bundles are com.apple.product-type.bundle, frameworks are com.apple.product-type.framework.
      target_is_resource_bundle = target.respond_to?(:product_type) && target.product_type == "com.apple.product-type.bundle"

      target.build_configurations.each do |build_configuration|
        # Build both x86_64 and arm64 simulator archs for all dependencies. If a single plugin does not support arm64 simulators,
        # the app and all frameworks will fall back to x86_64. Unfortunately that case is not detectable in this script.
        # Therefore all pods must have a x86_64 slice available, or linking a x86_64 app will fail.
        build_configuration.build_settings["ONLY_ACTIVE_ARCH"] = "NO" if build_configuration.type == :debug

        # Workaround https://github.com/CocoaPods/CocoaPods/issues/11402, do not sign resource bundles.
        if target_is_resource_bundle
          build_configuration.build_settings["CODE_SIGNING_ALLOWED"] = "NO"
          build_configuration.build_settings["CODE_SIGNING_REQUIRED"] = "NO"
          build_configuration.build_settings["CODE_SIGNING_IDENTITY"] = "-"
          build_configuration.build_settings["EXPANDED_CODE_SIGN_IDENTITY"] = "-"
        end

        # Bitcode is deprecated, Flutter.framework bitcode blob will have been stripped.
        build_configuration.build_settings["ENABLE_BITCODE"] = "NO"

        # Skip other updates if it's not a Flutter plugin (transitive dependency).
        next unless target.dependencies.any? do |dependency|
                      dependency.name == "Flutter"
                    end || (root_project_name.eql? target.name)

        # Profile can't be derived from the CocoaPods build configuration. Use release framework (for linking only).
        configuration_engine_dir = build_configuration.type == :debug ? debug_framework_dir : release_framework_dir
        Dir.new(configuration_engine_dir).each_child do |xcframework_file|
          next if xcframework_file.start_with?(".") # Hidden file, possibly on external disk.

          if xcframework_file.end_with?("-simulator") # ios-arm64_x86_64-simulator
            build_configuration.build_settings["FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]"] =
              "\"#{configuration_engine_dir}/#{xcframework_file}\" $(inherited)"
          elsif xcframework_file.start_with?("ios-") # ios-arm64
            build_configuration.build_settings["FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]"] =
              "\"#{configuration_engine_dir}/#{xcframework_file}\" $(inherited)"
            # else Info.plist or another platform.
          end
        end
        build_configuration.build_settings["OTHER_LDFLAGS"] = "$(inherited) -framework Flutter"

        build_configuration.build_settings["CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER"] = "NO"
        # Suppress warning when pod supports a version lower than the minimum supported by Xcode (Xcode 12 - iOS 9).
        # This warning is harmless but confusing--it's not a bad thing for dependencies to support a lower version.
        # When deleted, the deployment version will inherit from the higher version derived from the 'Runner' target.
        # If the pod only supports a higher version, do not delete to correctly produce an error.
        build_configuration.build_settings.delete "IPHONEOS_DEPLOYMENT_TARGET" if inherit_deployment_target

        # Override legacy Xcode 11 style VALID_ARCHS[sdk=iphonesimulator*]=x86_64 and prefer Xcode 12 EXCLUDED_ARCHS.
        build_configuration.build_settings["VALID_ARCHS[sdk=iphonesimulator*]"] = "$(ARCHS_STANDARD)"
        build_configuration.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "$(inherited) i386"
        build_configuration.build_settings["EXCLUDED_ARCHS[sdk=iphoneos*]"] = "$(inherited) armv7"
      end
    end
  end
end
