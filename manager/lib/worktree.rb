require "fileutils"
require "open3"

class Worktree
  SCHEMA = "backend/db/schema.rb"

  class << self
    def reset
      @root = nil
    end

    def root
      @root || Agent::ROOT
    end

    def root=(value)
      @root = value
    end

    def open(item)
      path = path_for(item)
      add(item, path) unless Dir.exist?(path)
      copy_files(path)
      path
    end

    def directory(item)
      path = path_for(item)
      Dir.exist?(path) ? path : root
    end

    def path_for(item)
      File.expand_path("../#{File.basename(root)}-#{branch_for(item)}", root)
    end

    private

    def add(item, path)
      run("git", "fetch", "origin")
      branch = branch_for(item)
      listed = refs
      if listed.match?(%r{ refs/heads/#{Regexp.escape(branch)}$})
        run("git", "worktree", "add", path, branch)
      elsif listed.match?(%r{ refs/remotes/origin/#{Regexp.escape(branch)}$})
        run("git", "worktree", "add", "-b", branch, path, "origin/#{branch}")
      else
        run("git", "worktree", "add", "-b", branch, path, "origin/master")
      end
    end

    def copy_files(path)
      env_files.each { |name| copy_file(name, path) }
      copy_file(SCHEMA, path)
    end

    def env_files
      Dir.children(root).select do |name|
        (name == ".env" || name.start_with?(".env.")) && name != ".env.default"
      end
    end

    def copy_file(relative, path)
      source = File.join(root, relative)
      return unless File.file?(source)

      destination = File.join(path, relative)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(source, destination)
    end

    def branch_for(item)
      Linear.identifier(item).downcase
    end

    def refs
      stdout, _stderr, status = Open3.capture3("git", "show-ref", chdir: root)
      status.success? ? stdout : ""
    end

    def run(*command)
      stdout, stderr, status = Open3.capture3(*command, chdir: root)
      message = stderr.strip
      message = stdout.strip if message.blank?
      raise "#{command.join(" ")} failed: #{message}" unless status.success?

      stdout
    end
  end
end
