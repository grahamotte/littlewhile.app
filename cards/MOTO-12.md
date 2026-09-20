# MOTO-12: manager nees to recover from http errors

- Identifier: MOTO-12
- ID: a2866c5a-bf3a-4834-87cc-967b49726d27
- URL: https://linear.app/gotte/issue/MOTO-12/manager-nees-to-recover-from-http-errors
- State: Completed
- Priority: No priority
- Estimate: none
- Due date: none
- Assignee: none
- Creator: linear@graham.lol
- Parent: none
- Children: none
- Labels: working
- Created: 2026-09-20T05:41:18.472Z
- Updated: 2026-09-20T07:15:38.086Z
- Completed: 2026-09-20T05:53:08.108Z

## Description

I got this when running mise manager:watch

```
[manager:watch] $ cd manager && bundle exec ruby watch.rb
/Users/graham/.local/share/mise/installs/ruby/4.0.6/lib/ruby/gems/4.0.0/gems/faraday-2.14.3/lib/faraday/response/raise_error.rb:38:in 'Faraday::Response::RaiseError#on_complete': the server responded with status 500 for POST http://127.0.0.1:57123/api/openchamber/sessions (Faraday::ServerError)
from /Users/graham/.local/share/mise/installs/ruby/4.0.6/lib/ruby/gems/4.0.0/gems/faraday-2.14.3/lib/faraday/middleware.rb:57:in 'block in Faraday::Middleware#call'
from /Users/graham/.local/share/mise/installs/ruby/4.0.6/lib/ruby/gems/4.0.0/gems/faraday-2.14.3/lib/faraday/response.rb:46:in 'Faraday::Response#on_complete'
from /Users/graham/.local/share/mise/installs/ruby/4.0.6/lib/ruby/gems/4.0.0/gems/faraday-2.14.3/lib/faraday/middleware.rb:56:in 'Faraday::Middleware#call'
from /Users/graham/.local/share/mise/installs/ruby/4.0.6/lib/ruby/gems/4.0.0/gems/faraday-2.14.3/lib/faraday/rack_builder.rb:158:in 'Faraday::RackBuilder#build_response'
from /Users/graham/.local/share/mise/installs/ruby/4.0.6/lib/ruby/gems/4.0.0/gems/faraday-2.14.3/lib/faraday/connection.rb:452:in 'Faraday::Connection#run_request'
from /Users/graham/.local/share/mise/installs/ruby/4.0.6/lib/ruby/gems/4.0.0/gems/faraday-2.14.3/lib/faraday/connection.rb:280:in 'Faraday::Connection#post'
from /Users/graham/Code/codemoto.org/manager/lib/req.rb:11:in 'Req.call'
from /Users/graham/Code/codemoto.org/manager/lib/agent.rb:22:in 'Agent.openchamber'
from /Users/graham/Code/codemoto.org/manager/lib/agent.rb:9:in 'Agent.start'
from /Users/graham/Code/codemoto.org/manager/lib/trigger.rb:13:in 'block in Trigger.call'
from /Users/graham/Code/codemoto.org/manager/lib/trigger.rb:8:in 'Array#each'
from /Users/graham/Code/codemoto.org/manager/lib/trigger.rb:8:in 'Trigger.call'
from watch.rb:4:in 'block in '
from watch.rb:3:in 'Kernel#loop'
from watch.rb:3:in ''
Finished in 1516.08s
```

this should log to the console, but not kill the whole watcher because it's likely transient

## Comments

### linear@graham.lol — 2026-09-20T05:52:17.505Z

- ID: 85a95a9d-b583-4d91-b8ba-a51de028fb55
- Updated: 2026-09-20T05:52:17.490Z

HTTP errors no longer kill `mise manager:watch`. Faraday failures (including OpenChamber 500s) are logged and the watcher keeps looping so the next tick can retry. PR: https://github.com/grahamotte/codemoto.org/pull/10

## Attachments

- [Keep the manager watcher running when HTTP requests fail.](https://github.com/grahamotte/codemoto.org/pull/10)
