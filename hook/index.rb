r = Nginx::Request.new
r.content_type = "text/html"

Docker::Container.expire_cache!
me = Docker::Container.me!
containers = Docker::Container.all - [me]

not_connected_networks = (containers.flat_map(&:networks) - me.networks)
not_connected_networks.each do |n|
  n.connect(me)
end
if not_connected_networks.any?
  Docker::Container.expire_cache!
  me = Docker::Container.me!
  containers = Docker::Container.all - [me]
end
containers = containers.select {|c| c.reachable_from?(me) }.sort_by(&:name)

Nginx.echo <<-HTML
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <title>Repro</title>
    <link rel="stylesheet" href="https://cdn.rawgit.com/andyferra/2554919/raw/2e66cabdafe1c9a7f354aa2ebf5bc38265e638e5/github.css" type="text/css" />
  </head>
  <body>
    <a href="https://github.com/riy0/repro">
      riy0/repro
    </a>
    <h1>Proxy-able Containers</h1>
    <ul>
    #{
      containers.flat_map do |c|
        me.exposed_ports.select { |_, local| c.listening?(me, local) }.map do |remote, local|
          "<li><a href='http://#{c.host}.#{r.hostname}:#{remote}' target='_blank'>#{c.name} (#{remote}:#{local})</a></li>"
        end
      end.join("\n")
    }
    </ul>
    <h1>All Containers</h1>
    <ul>
    #{
      containers.map { |c| "<li>#{c.name}</li>" }.join("\n")
    }
    </ul>
  </body>
</html>
HTML
