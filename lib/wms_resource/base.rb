module WmsResource
  class Base < ::Hashie::Mash

    class << self
      def base_url(url = nil)
        @base_url = url if url
        @base_url || WmsResource.base_url
      end

      def service_url
        @service_url ||= base_url + "/" + name.split('::').last.downcase
      end

      def query(params)
        params ? "?" + params.to_a.map{|param| param.join('=')}.join('&') : params
      end

      def request_url(path, args = {})
        "#{service_url}/#{path}#{query(args[:query])}"
      end

      def errors
        @errors ||= []
      end

      def errors?
        not errors.empty?
      end

      def json
        @json
      end

      def response
        @resonse
      end

      def get(*args)

        if args.first.kind_of?(String)
          path = args.shift
          args = args.first
        elsif args.first.kind_of?(Hash)
          args = args.first
          path = args[:first] || ""
        end

        url = URI.parse(request_url(path, args))

        begin
          errors.clear

          @response = Net::HTTP.get_response(url)

          errors << "ExternalServiceError: Response code #{@response.code}" unless @response.code.to_s == "200"
          errors << "ExternalServiceError: Empty body response" if @response.body.to_s.empty?

          @json = JSON.parse(@response.body)

          if @json["status"] != "success"
            errors << "ExternalServiceError: #{@json['message']}"
          elsif @json["data"].nil? 
            errors << "ExternalServiceError: Malformed WMS response object. Can not find :data key"
          elsif @json["data"]["result_list"].nil?
            errors << "ExternalServiceError: Malformed WMS response object. Can not find :result_list key"
          elsif not @json["data"]["result_list"].kind_of?(Array)
            errors << "ExternalServiceError: Malformed WMS response object. :result_list is not an array"
          else
            @result_list = @json["data"]["result_list"].map {|result| new(result) }
          end

        rescue => e
          errors << e.message
        end

        @result_list ||= []
        args[:first] ? @result_list.first : @result_list
      end
    end
  end
end
