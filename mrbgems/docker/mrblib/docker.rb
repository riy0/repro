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
    class NotFound < StandardError; end

    class << self
      def all
        @all ||= begin
          ids = `docker ps -q --no-trunc`.lines.map(&:chomp)
          return [] if ids.empty?

          data = JSON.parse(`docker container inspect #{ids.join(' ')}`)
          data.map do |d|
            new(d)
          end
        end
      end

      def my_id
        @my_id ||= `hostname`.chomp
      end

      def me!(timeout_sec = 3)
        return me if me

        timeout_sec.times do
          sleep 1
          expire_cache!
          return me if me
        end
        raise NotFound
      end

      def find_by_hostname(hostname)
        host = hostname.split('.').first
        all.find { |c| c.host == host }
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

    def networks
      data['NetworkSettings']['Networks'].values.map { |v| Network.new(v['NetworkID']) }
    end

    def exposed_ports
      data['NetworkSettings']['Ports'].select { |k, _| k.include?('tcp') }.map do |k, v|
        [v[0]['HostPort'].to_i, k.scan(/\d+/)[0].to_i]
      end
    end

    def ip_address(container)
      network = shared_network_with(container)
      data['NetworkSettings']['Networks'].values.find { |n| n['NetworkID'] == network.id }['IPAddress']
    end

    def reachable_from?(container)
      !!shared_network_with(container)
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

    def shared_network_with(container)
      (container.networks & networks).first
    end
  end
end
