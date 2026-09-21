require_relative "test_helper"

class TriggerTest < Minitest::Test
  def test_moves_ready_cards_and_starts_work_agent
    calls = stub_manager(
      items: [
        { id: "item-1", identifier: "MOTO-1", url: "https://linear.app/gotte/issue/MOTO-1", state: { id: "s-ready", name: "Ready" } },
        { id: "item-2", identifier: "MOTO-2", url: "https://linear.app/gotte/issue/MOTO-2", state: { id: "s-planned", name: "Planned" } },
      ],
    )

    output, = capture_io { Trigger.call }

    assert_equal "started working on MOTO-1\n", output
    assert_equal(
      [
        { stateId: "s-working" },
        { addedLabelIds: [ "l-working" ] },
      ],
      issue_update_inputs(calls),
    )
    prompt = prompt_for(calls, "MOTO-1")
    assert_includes prompt, "Do this Linear issue: https://linear.app/gotte/issue/MOTO-1"
    assert_includes prompt, "This may be a new card or a kickback with corrections in later comments."
    assert_includes prompt, "There may already be a worktree, commits, and a PR."
    assert_includes prompt, "This session is already in the card worktree. Env files and schema.rb were copied from the main checkout."
    assert_includes prompt, "Rebase onto the current origin main. Do not hard-reset; keep existing commits."
    assert_includes prompt, "You may edit existing commits or add new ones."
    assert_includes prompt, "Open a GitHub PR with `gh pr create` using `GITHUB_TOKEN`"
    assert_includes prompt, "Comment on the card describing what you did"
    assert_includes prompt, "Remove the working tag"
    assert_includes prompt, "Move the card to review"
    assert_includes prompt, "Move the card to planned"
    refute_includes prompt, "Hard set to the current origin main."
    refute_includes prompt, "Open a worktree."
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-2") }
    assert_equal Worktree.path_for({ identifier: "MOTO-1" }), directory_for(calls, "MOTO-1")
    assert_equal "xai/grok-4.6", session_for(calls, "MOTO-1").fetch(:model)
    assert_equal "high", session_for(calls, "MOTO-1").fetch(:variant)
  end

  def test_starts_agent_with_model_and_variant_labels
    calls = stub_manager(
      items: [
        {
          id: "item-1",
          identifier: "MOTO-1",
          url: "https://linear.app/gotte/issue/MOTO-1",
          state: { id: "s-ready", name: "Ready" },
          labels: {
            nodes: [
              { id: "l-model", name: "model: anthropic/claude-sonnet-4" },
              { id: "l-variant", name: "variant: medium" },
            ],
          },
        },
      ],
    )

    capture_io { Trigger.call }

    session = session_for(calls, "MOTO-1")
    assert_equal "anthropic/claude-sonnet-4", session.fetch(:model)
    assert_equal "medium", session.fetch(:variant)
  end

  def test_starts_merge_agent_for_approved_cards
    calls = stub_manager(
      items: [
        { id: "item-3", identifier: "MOTO-3", url: "https://linear.app/gotte/issue/MOTO-3", state: { id: "s-approved", name: "Approved" } },
      ],
    )

    output, = capture_io { Trigger.call }

    assert_equal "merging MOTO-3\n", output
    assert_equal(
      [ { addedLabelIds: [ "l-working" ] } ],
      issue_update_inputs(calls),
    )
    prompt = prompt_for(calls, "MOTO-3")
    assert_includes prompt, "This Linear issue is approved: https://linear.app/gotte/issue/MOTO-3"
    assert_includes prompt, "Rebase the GitHub PR on the card."
    assert_includes prompt, "Merge the PR with `gh pr merge` using `GITHUB_TOKEN`."
    assert_includes prompt, "Remove the working tag."
    assert_includes prompt, "Move the card to completed."
    assert_equal Worktree.root, directory_for(calls, "MOTO-3")
  end

  def test_moves_ready_card_back_when_agent_fails
    calls = stub_manager(
      items: [
        { id: "item-1", identifier: "MOTO-1", url: "https://linear.app/gotte/issue/MOTO-1", state: { id: "s-ready", name: "Ready" } },
      ],
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless opts[:url].to_s.end_with?("/api/openchamber/sessions")

      true
    end.raises("agent failed")

    output, = capture_io do
      assert_raises(RuntimeError) { Trigger.call }
    end

    assert_equal "", output
    assert_equal(
      [
        { stateId: "s-working" },
        { addedLabelIds: [ "l-working" ] },
        { removedLabelIds: [ "l-working" ] },
        { stateId: "s-ready" },
      ],
      issue_update_inputs(calls),
    )
  end

  def test_untags_when_approved_agent_fails
    calls = stub_manager(
      items: [
        { id: "item-3", identifier: "MOTO-3", url: "https://linear.app/gotte/issue/MOTO-3", state: { id: "s-approved", name: "Approved" } },
      ],
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless opts[:url].to_s.end_with?("/api/openchamber/sessions")

      true
    end.raises("agent failed")

    output, = capture_io do
      assert_raises(RuntimeError) { Trigger.call }
    end

    assert_equal "", output
    assert_equal(
      [
        { addedLabelIds: [ "l-working" ] },
        { removedLabelIds: [ "l-working" ] },
      ],
      issue_update_inputs(calls),
    )
  end

  def test_skips_completed_and_canceled_cards
    calls = stub_manager(
      items: [
        { id: "item-4", identifier: "MOTO-4", url: "https://linear.app/gotte/issue/MOTO-4", state: { id: "s-completed", name: "Completed" } },
        { id: "item-5", identifier: "MOTO-5", url: "https://linear.app/gotte/issue/MOTO-5", state: { id: "s-canceled", name: "Canceled" } },
      ],
    )

    output, = capture_io { Trigger.call }

    assert_equal "", output
    assert_empty issue_update_inputs(calls)
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-4") }
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-5") }
  end

  def test_starts_one_agent_per_step
    calls = stub_manager(
      items: [
        { id: "item-1", identifier: "MOTO-1", url: "https://linear.app/gotte/issue/MOTO-1", state: { id: "s-ready", name: "Ready" } },
        { id: "item-1b", identifier: "MOTO-8", url: "https://linear.app/gotte/issue/MOTO-8", state: { id: "s-ready", name: "Ready" } },
        { id: "item-3", identifier: "MOTO-3", url: "https://linear.app/gotte/issue/MOTO-3", state: { id: "s-approved", name: "Approved" } },
        { id: "item-3b", identifier: "MOTO-9", url: "https://linear.app/gotte/issue/MOTO-9", state: { id: "s-approved", name: "Approved" } },
        { id: "item-4", identifier: "MOTO-4", url: "https://linear.app/gotte/issue/MOTO-4", state: { id: "s-completed", name: "Completed" } },
        { id: "item-4b", identifier: "MOTO-10", url: "https://linear.app/gotte/issue/MOTO-10", state: { id: "s-completed", name: "Completed" } },
        { id: "item-5", identifier: "MOTO-5", url: "https://linear.app/gotte/issue/MOTO-5", state: { id: "s-canceled", name: "Canceled" } },
        { id: "item-5b", identifier: "MOTO-12", url: "https://linear.app/gotte/issue/MOTO-12", state: { id: "s-canceled", name: "Canceled" } },
      ],
    )

    output, = capture_io { Trigger.call }

    assert_equal "started working on MOTO-1\nmerging MOTO-3\n", output
    assert_equal 3, calls.count { |call| graphql?(call, "mutation IssueUpdate") }
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-8") }
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-9") }
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-10") }
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-12") }
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-4") }
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-5") }
    assert prompt_for(calls, "MOTO-1")
    assert prompt_for(calls, "MOTO-3")
  end

  def test_handles_ready_and_approved_together
    calls = stub_manager(
      items: [
        { id: "item-1", identifier: "MOTO-1", url: "https://linear.app/gotte/issue/MOTO-1", state: { id: "s-ready", name: "Ready" } },
        { id: "item-3", identifier: "MOTO-3", url: "https://linear.app/gotte/issue/MOTO-3", state: { id: "s-approved", name: "Approved" } },
      ],
    )

    output, = capture_io { Trigger.call }

    assert_equal "started working on MOTO-1\nmerging MOTO-3\n", output
    assert_equal 3, calls.count { |call| graphql?(call, "mutation IssueUpdate") }
    assert_includes prompt_for(calls, "MOTO-1"), "This session is already in the card worktree. Env files and schema.rb were copied from the main checkout."
    assert_includes prompt_for(calls, "MOTO-1"), "Rebase onto the current origin main. Do not hard-reset; keep existing commits."
    assert_includes prompt_for(calls, "MOTO-3"), "Rebase the GitHub PR on the card."
    assert_equal Worktree.path_for({ identifier: "MOTO-1" }), directory_for(calls, "MOTO-1")
    assert_equal Worktree.root, directory_for(calls, "MOTO-3")
  end

  def test_copies_env_and_schema_into_worktree_before_starting
    File.write(File.join(Worktree.root, ".env.development"), "DEV=1")
    FileUtils.mkdir_p(File.join(Worktree.root, "backend/db"))
    File.write(File.join(Worktree.root, "backend/db/schema.rb"), "schema")
    stub_manager(
      items: [
        { id: "item-1", identifier: "MOTO-1", url: "https://linear.app/gotte/issue/MOTO-1", state: { id: "s-ready", name: "Ready" } },
      ],
    )

    capture_io { Trigger.call }

    path = Worktree.path_for({ identifier: "MOTO-1" })
    assert_equal "DEV=1", File.read(File.join(path, ".env.development"))
    assert_equal "schema", File.read(File.join(path, "backend/db/schema.rb"))
  end

  def test_merges_from_existing_worktree
    path = Worktree.path_for({ identifier: "MOTO-3" })
    FileUtils.mkdir_p(path)
    calls = stub_manager(
      items: [
        { id: "item-3", identifier: "MOTO-3", url: "https://linear.app/gotte/issue/MOTO-3", state: { id: "s-approved", name: "Approved" } },
      ],
    )

    capture_io { Trigger.call }

    assert_equal path, directory_for(calls, "MOTO-3")
  end

  def test_skips_cards_with_working_tag
    calls = stub_manager(
      items: [
        { id: "item-3", identifier: "MOTO-3", url: "https://linear.app/gotte/issue/MOTO-3", state: { id: "s-approved", name: "Approved" }, labels: { nodes: [ { id: "l-working", name: "working" } ] } },
        { id: "item-9", identifier: "MOTO-9", url: "https://linear.app/gotte/issue/MOTO-9", state: { id: "s-approved", name: "Approved" } },
      ],
    )

    output, = capture_io { Trigger.call }

    assert_equal "merging MOTO-9\n", output
    refute calls.any? { |call| call[:prompt].to_s.include?("MOTO-3") }
    assert_equal(
      [ { addedLabelIds: [ "l-working" ] } ],
      issue_update_inputs(calls),
    )
    assert_equal "item-9", calls.find { |call| graphql?(call, "mutation IssueUpdate") }.dig(:payload, :variables, :id)
  end

  def test_skips_column_when_all_cards_have_working_tag
    stub_manager(
      items: [
        { id: "item-3", identifier: "MOTO-3", url: "https://linear.app/gotte/issue/MOTO-3", state: { id: "s-approved", name: "Approved" }, labels: { nodes: [ { id: "l-working", name: "working" } ] } },
      ],
    )

    assert_output("") { Trigger.call }
  end

  def test_prints_nothing_when_nothing_is_triggered
    stub_manager(
      items: [
        { id: "item-2", identifier: "MOTO-2", url: "https://linear.app/gotte/issue/MOTO-2", state: { id: "s-planned", name: "Planned" } },
      ],
    )

    assert_output("") { Trigger.call }
  end

  private

  def graphql?(opts, fragment)
    opts[:url] == Linear::HOST && opts.dig(:payload, :query).to_s.include?(fragment)
  end

  def stub_manager(items:)
    calls = []
    ok = Object.new
    ok.define_singleton_method(:success?) { true }
    Open3.stubs(:capture3).with do |*args, **_kwargs|
      if args[1] == "worktree" && args[2] == "add"
        path = args[3] == "-b" ? args[5] : args[3]
        FileUtils.mkdir_p(path)
      end
      true
    end.returns([ "", "", ok ])
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless opts[:url].to_s.end_with?("/api/openchamber/sessions")

      calls << {
        prompt: opts.dig(:payload, :prompt),
        directory: opts.dig(:payload, :directory),
        model: opts.dig(:payload, :model),
        variant: opts.dig(:payload, :variant),
      }
      true
    end.returns({ sessionId: "ses-1" })
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query Workspace")

      calls << opts
      true
    end.returns(
      {
        data: {
          organization: { urlKey: "gotte" },
          teams: { nodes: [ { id: "team-1", key: "MOTO" } ] },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query States")

      calls << opts
      true
    end.returns(
      {
        data: {
          team: {
            states: {
              nodes: [
                { id: "s-ready", name: "Ready", type: "started" },
                { id: "s-working", name: "Working", type: "started" },
                { id: "s-planned", name: "Planned", type: "unstarted" },
                { id: "s-approved", name: "Approved", type: "started" },
              ],
            },
          },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query Issues")

      calls << opts
      true
    end.returns(
      {
        data: {
          team: {
            issues: {
              nodes: items,
              pageInfo: { hasNextPage: false, endCursor: nil },
            },
          },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query Tags")

      calls << opts
      true
    end.returns(
      {
        data: {
          team: {
            labels: {
              nodes: [ { id: "l-working", name: "working" } ],
            },
          },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "mutation IssueUpdate")

      calls << opts
      true
    end.returns({ data: { issueUpdate: { success: true } } })
    calls
  end

  def issue_update_inputs(calls)
    calls.select { |call| graphql?(call, "mutation IssueUpdate") }.map { |call| call.dig(:payload, :variables, :input) }
  end

  def prompt_for(calls, identifier)
    calls
      .map { |call| call[:prompt] }
      .compact
      .find { |text| text.include?(identifier) }
  end

  def directory_for(calls, identifier)
    session_for(calls, identifier)&.fetch(:directory)
  end

  def session_for(calls, identifier)
    calls.find { |call| call[:prompt].to_s.include?(identifier) }
  end
end
