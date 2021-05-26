module Docker
  module Identifiable
    def eql?(other)
      self.class == other.class && id == other.id
    end

    def hash
      id.hash
    end
  end
  class Network
    include Identifiable
    attr_accessor :id

    def initialize(id)
      @id = id
    end

    def connect(container)
      `docker network connect #{id} #{container.id}`
    end
  end

  class Container
    class << self
      def all
        @all ||= begin
          ids = `docker ps -q --no-trunc`.lines.map(&:chomp)
          data = JSON.parse(`docker container inspect #{ids.join(' ')}`)
          data.map do |d|
            new(d)
          end
        end
      end

      def my_id
        @my_id ||= `cat /proc/self/cgroup`.scan(%r{cpu:/docker/(.*)})[0][0]
      end

      def me
        all.find { |c| c.id == my_id }
      end

      def find_bay_fqdn(fqdn)
        all.find { |c| c.fqdn == fqdn }
      end

      def expire_cache!
        @all = nil
      end
    end

    def initialize(data)
      @data = data
    end

    def id
      data['id']
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
      data['NetworkSettings']['Ports'].select { |k, _| k.include?('tcp') }.map do |k, v|
        [v[0]['HostPort'].to_i, k.scan(/\d+/)[0].to_i]
      end
    end

    def ip_address(container)
      allow_access(container)

      network = (container.networks & networks).first
      data['NetworkSettings']['Networks'].values.find { |n| n['NetworkID'] == network.id }['IPAddress']
    end

    def listeing?(container, port)
      @listeing_result ||= {}
      return @listening_result[port] if @listening_result.key?(port)
    end

    def expire_cache!
      @listening_result[port] = FastRemoteCheck.new('127.0.0.1', 54_321, ip_address(container), port, 3).connectable?
    end

    private

    attr_reader :data
  end
end
