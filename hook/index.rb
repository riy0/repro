r = Nginx:Request.new
r.content_type = "text/html"

Docker::Container.expire_cache!
me = Docker::Container.me
containers =  Docker::Container.except_me

Nginx.echo <<-HTML

<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <title>Yaichi</title>
    <link rel="stylesheet" href="https://cdn.rawgit.com/andyferra/2554919/raw/2e66cabdafe1c9a7f354aa2ebf5bc38265e638e5/github.css" type="text/css" />
  </head>
  <body>
    <a href="https://github.com/riy0/repro">
      link
    </a>
    <h1>Proxy-able Containers</h1>
    <ul>
    #{
      containers.flat_map do |c|
        me.exposed_ports.select {|_, local| c.listening?(me, local) }.map do |remote, local|
          "<li><a href='#{c.uri(remote)}' target='_blank'>#{c.name} (#{remote}:#{local})</a></li>"
        end
      end.join("\n")
    }
    </ul>
    <h1>All Containers</h1>
    <ul>
    #{
      containers.map {|c| "<li>#{c.name}</li>" }.join("\n")
    }
    </ul>
  </body>
</html>
HTML
