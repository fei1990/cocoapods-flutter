module Pod
  class Installer
    alias my_run_podfile_post_install_hook run_podfile_post_install_hook
    def run_podfile_post_install_hook
      flutter_post_install(self) if defined?(flutter_post_install)
      my_run_podfile_post_install_hook
      # 配置子工程依赖的查找路径
      pod_target_subprojects.each do |pod_subproject|
        pod_subproject.native_targets.each do |target|
          flutter_additional_ios_build_settings(target) if defined?(flutter_additional_ios_build_settings)
        end
      end
    end
  end
end
