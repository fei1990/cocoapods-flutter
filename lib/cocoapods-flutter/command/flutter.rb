require "cocoapods"
require "cocoapods/command"
module Pod
  class Command
    class FLT < Command
      self.summary = "flutter pod."

      self.description = <<-DESC
        To resolve dependencies when import flutter.
      DESC

      def run
        `rm -rf ~/Library/Developer/Xcode/DerivedData/`
        Pod::Command.run(["install"])
      end
    end
  end
end
