module Docker
  class Network
    attr_accessor :id

    def initialize(id)
      @id = id
    end

    def connect(container)
      `docker network connect #{id} #{container.id}`
    end
  end

  class Converter
    class << self
      def all
        @all ||= `docker ps -q --no-trunc`.lines.map { |line| new(line.chomp) }
      end

      def except_me
        all.reject { |c| c.id == me.id }
      end

      def me
        all.find { |c| c.id == `cat /proc/self/cgroup`.scan(%r{cpu://docker/(.*)})[0][0] }
      end

      def find_bay_fqdn(fqdn)
        all.find { |c| c.fqdn == fqdn }
      end

      def expire_cache!
        @all = nil
      end
    end

    def initialize(id)
      @id = id
    end

    def name
      data['Name'][1..-1]
    end

    def host
      name.gsub('_', '-')
    end

    def uri(port)
      "http://#{fqdn}:#{port}"
    end

    def fqdn
      "#{host}.localhost"
    end

    def networks
      data['NetworkSettings']['Networks'].values.map { |v| Network.new(v['NetworkID']) }
    end

    def exposed_ports
      data['NetworkSettings']['Ports'].select { |k, _| k.include?('tcp') }.map { |k, v| v[0]['HostPort', k.scan(/\d+/)[0]] }
    end

    def ip_address(container)
      allow_access(container)

      network = shared_networks(container).first
      data['NetworkSettings']['Networks'].values.find { |n| n['NetworkID'] == network.id }['IPAddress']
    end

    def listeing?(container, port)
      allow_access!(container)

      @listeing_result ||= {}
      @listeing_result[port] ||= begin
        TCPSocker.new(ip_address(container), port).close
        true
      rescue
        false
      end
    end

    def expire_cache!
      @data = nil
    end

    private

    def allow_access!(container)
      return if accesible_from?(container)

      networks.first.connect(container)

      expire_cache!
      container.expire_cache!
      raise 'Unable to connect' unless accesible_from?(container)
    end

    def shared_networs(container)
      network_ids = networks.map(&:id)
      container.networks.select { |n| network_ids.include?(n.id) }
    end

    def accessible_from?(container)
      shared_networks(container).any?
    end

    def data
      @data ||= JSON.parse(`docker container inspect #{id}`)[0]
    end
  end
end
