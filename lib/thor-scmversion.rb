require 'pathname'
require 'tmpdir'
require 'thor'
require 'thor-scmversion/prerelease'
require 'thor-scmversion/scm_version'
require 'thor-scmversion/git_version'
require 'thor-scmversion/p4_version'
require 'thor-scmversion/shell_utils'
require 'thor-scmversion/errors'

module ThorSCMVersion
  class Tasks < Thor
    namespace "version"

    desc "bump TYPE [PRERELEASE_TYPE]", "Bump version number (type is major, minor, patch, prerelease or auto)"
    method_option :default, type: :string, aliases: "-d"
    def bump(type, prerelease_type = nil)
      current_version.bump! type, options.merge(prerelease_type: prerelease_type)
      begin
        say "Creating and pushing tags", :yellow
        current_version.tag
        say "Writing files: #{version_files.join(', ')}", :yellow
        write_version
        say "Tagged: #{current_version}", :green
      rescue => e
        say "Tagging #{current_version} failed due to error", :red
        say e.to_s, :red
        if e.respond_to? :status_code
          exit e.status_code
        else
          exit 1
        end
      end
    end

    desc "bump_file TYPE [PRERELEASE_TYPE]", "Bump version number & commits VERSION file and git pushes(type is major, minor, patch, prerelease or auto)"
    method_option :default, type: :string, aliases: "-d"
    def bump_file(type, prerelease_type = nil)
      current_version.bump! type, options.merge(prerelease_type: prerelease_type)
      begin
        say "Writing files: #{version_files.join(', ')}", :yellow
        write_version
        say "Creating and pushing tags & Version File", :yellow
        current_version.commit_push
        say "Tagged: #{current_version}", :green
      rescue => e
        say "Tagging #{current_version} and pushing VERSION file failed due to error", :red
        say e.to_s, :red
        if e.respond_to? :status_code
          exit e.status_code
        else
          exit 1
        end
      end
    end

    method_option :version_file_path,
      :type => :string,
      :default => nil,
      :desc => "An additional path to copy a VERSION file to on the file system."
    desc "current", "Show current SCM tagged version"
    def current
      write_version(options[:version_file_path])
      say current_version.to_s
    end

    private
    def current_version
      @current_version ||= ThorSCMVersion.versioner.from_path
    end

    def write_version(version_file_path=nil)
      files_to_write = version_files
      files_to_write << File.join(File.expand_path(version_file_path), 'VERSION') if version_file_path
      current_version.write_version(files_to_write)
    end

    eval "def source_root ; Pathname.new File.dirname(__FILE__) ; end"
    def version_files
      [
       source_root.join('VERSION')
      ]
    end
  end
end
