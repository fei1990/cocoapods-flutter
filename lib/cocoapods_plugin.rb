# require "cocoapods-flutter/command"
# 暴漏头文件（命令、插件）
require 'pathname'
require "cocoapods"
require "source_ext"
require "flutter_pod"
require "install_hooks"
module Pod
  class Installer
    alias my_run_plugins_post_install_hooks run_plugins_post_install_hooks
    def run_plugins_post_install_hooks
      CocoapodsHook.installer = self
      my_run_plugins_post_install_hooks
    end
  end

  module CocoapodsHook
    # 给CocoapodsHook扩展一个属性
    class << self
      attr_accessor :installer
    end

    @hooks_manager = Pod::HooksManager
    @hooks_manager.register("cocoapods-flutter", :pre_integrate) do |_context, _option|
      p "pre_integrate"
    end
    @hooks_manager.register("cocoapods-flutter", :pre_install) do |_content, _options|
      puts "pre_install"
      spec_path1 = File.expand_path("~/.cocoapods/repos/ios_sohu_spec/")
      spec_path2 = File.expand_path("~/.cocoapods/repos/SHSpecs/")
      p = Pathname.new(spec_path1)
      if Dir.exist?(p.realpath)
        `pod repo update ~/.cocoapods/repos/ios_sohu_spec/`
      else
        `pod repo add ios_sohu_spec git@code.sohuno.com:mtpc_sh_ios/ios_sohu_spec.git`
      end

      if File.exist?(spec_path2)
        `pod repo update ~/.cocoapods/repos/SHSpecs/`
      else
        `pod repo add SHSpecs git@code.sohuno.com:MPTC-iOS/SHSpecs.git`
      end
    end
    @hooks_manager.register("cocoapods-flutter", :source_provider) do |context, _options|
      puts "source_provider"
      source_manager = Pod::Config.instance.sources_manager
      context.add_source(source_manager.private_source1)
      context.add_source(source_manager.private_source2)
    end
    @hooks_manager.register("cocoapods-flutter", :post_install) do |_context, _options|
    end
  end
end
