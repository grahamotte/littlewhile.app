require_relative "test_helper"

class WorktreeTest < Minitest::Test
  def test_opens_new_worktree_from_origin_master
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    write_source(".env.development", "DEV=1")
    write_source(".env.production", "PROD=1")
    write_source("backend/db/schema.rb", "schema")
    stub_git

    assert_equal path, Worktree.open(item)

    assert_includes git_commands, [ "git", "fetch", "origin" ]
    assert_includes git_commands, [ "git", "worktree", "add", "-b", "moto-17", path, "origin/master" ]
    assert_equal "DEV=1", File.read(File.join(path, ".env.development"))
    assert_equal "PROD=1", File.read(File.join(path, ".env.production"))
    assert_equal "schema", File.read(File.join(path, "backend/db/schema.rb"))
  end

  def test_adds_existing_local_branch
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    stub_git(show_ref: "abc refs/heads/moto-17\n")

    Worktree.open(item)

    assert_includes git_commands, [ "git", "worktree", "add", path, "moto-17" ]
    refute_includes git_commands, [ "git", "worktree", "add", "-b", "moto-17", path, "origin/master" ]
  end

  def test_adds_existing_remote_branch
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    stub_git(show_ref: "abc refs/remotes/origin/moto-17\n")

    Worktree.open(item)

    assert_includes git_commands, [ "git", "worktree", "add", "-b", "moto-17", path, "origin/moto-17" ]
  end

  def test_prefers_local_branch_over_remote
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    stub_git(show_ref: "abc refs/heads/moto-17\ndef refs/remotes/origin/moto-17\n")

    Worktree.open(item)

    assert_includes git_commands, [ "git", "worktree", "add", path, "moto-17" ]
    refute git_commands.any? { |command| command.include?("-b") }
  end

  def test_skips_git_when_worktree_already_exists
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    FileUtils.mkdir_p(path)
    write_source(".env.development", "DEV=1")

    Worktree.open(item)

    assert_equal [], git_commands
    assert_equal "DEV=1", File.read(File.join(path, ".env.development"))
  end

  def test_overwrites_existing_copied_files
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    FileUtils.mkdir_p(path)
    File.write(File.join(path, ".env.development"), "OLD")
    write_source(".env.development", "NEW")

    Worktree.open(item)

    assert_equal "NEW", File.read(File.join(path, ".env.development"))
  end

  def test_skips_missing_and_tracked_env_files
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    write_source(".env.default", "tracked")
    write_source("backend/db/schema.rb", "schema")
    stub_git

    Worktree.open(item)

    refute File.exist?(File.join(path, ".env.development"))
    refute File.exist?(File.join(path, ".env.default"))
    assert_equal "schema", File.read(File.join(path, "backend/db/schema.rb"))
  end

  def test_copies_root_env_file
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    write_source(".env", "SECRET=1")
    stub_git

    Worktree.open(item)

    assert_equal "SECRET=1", File.read(File.join(path, ".env"))
  end

  def test_directory_uses_existing_worktree
    item = { identifier: "MOTO-17" }
    path = Worktree.path_for(item)
    FileUtils.mkdir_p(path)

    assert_equal path, Worktree.directory(item)
  end

  def test_directory_falls_back_to_root
    assert_equal Worktree.root, Worktree.directory({ identifier: "MOTO-17" })
  end

  def test_raises_when_git_fails
    Open3.stubs(:capture3).returns([ "", "network error", status(false) ])

    error = assert_raises(RuntimeError) { Worktree.open({ identifier: "MOTO-17" }) }

    assert_equal "git fetch origin failed: network error", error.message
  end

  def test_path_uses_repo_basename_and_downcased_identifier
    assert_equal(
      File.expand_path("../#{File.basename(Worktree.root)}-moto-17", Worktree.root),
      Worktree.path_for({ identifier: "MOTO-17" }),
    )
  end

  private

  def git_commands
    @git_commands || []
  end

  def write_source(relative, contents)
    path = File.join(Worktree.root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end

  def stub_git(show_ref: "")
    @git_commands = []
    ok = status(true)
    Open3.stubs(:capture3).with do |*args, **_kwargs|
      next false if args == [ "git", "show-ref" ]

      @git_commands << args
      if args[1] == "worktree" && args[2] == "add"
        path = args[3] == "-b" ? args[5] : args[3]
        FileUtils.mkdir_p(path)
      end
      true
    end.returns([ "", "", ok ])
    Open3.stubs(:capture3).with("git", "show-ref", chdir: Worktree.root).returns([ show_ref, "", ok ])
  end

  def status(success)
    Object.new.tap { |object| object.define_singleton_method(:success?) { success } }
  end
end
