require 'spec_helper'

module WmsResource

  describe Base do
    let(:base_url) { "http://foo.bar" }
    before(:each) do
      WmsResource.base_url = base_url
      class Biz < Base; end
      Biz.base_url nil
    end

    describe ".base_url" do
      it "should return WmsResource base_url if not defined for a class" do
        Biz.base_url.should == "http://foo.bar"
      end

      it "should return class base_url if defined" do
        class Baz < Base; end

        Baz.base_url "http://baz.bar"
        Baz.base_url.should == "http://baz.bar"
      end
    end

    describe ".service_url" do
      it "should have a service_url" do
        Biz.service_url.should == "http://foo.bar/biz"
      end
    end

    describe ".request_url" do
      it "should concat service_url with path" do
        Biz.request_url('test/1/test').should == "http://foo.bar/biz/test/1/test"
      end

      it "should concat service_url with path and query" do
        Biz.request_url('test/1/test', query: { a: 'b', c: 'd' }).should == "http://foo.bar/biz/test/1/test?a=b&c=d"
      end
    end

    describe ".query" do
      it "should return nil if params are nil" do
        Biz.query(nil).should == nil
      end

      it "should generate query" do
        Biz.query(foo: 1, bar: 'a').should == "?foo=1&bar=a"
      end
    end

    describe ".errors" do
      it "should accept errors" do
        Biz.errors?.should == false
        Biz.errors << "test error"
        Biz.errors?.should == true
      end
    end

    describe ".get" do
      it "should request based on path and query" do
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => { status: 'success', data: {result_list: []} }.to_json, :headers => {})

        Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        Biz.errors?.should == false
      end

      it "should error when response code is not 200" do
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 400, :body => { status: 'success' }.to_json, :headers => {})

        Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        Biz.errors?.should == true
        Biz.errors.first.should == "ExternalServiceError: Response code 400"
      end

      it "should error when the body is empty" do
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

        Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        Biz.errors?.should == true
        Biz.errors.first.should == "ExternalServiceError: Empty body response"
      end

      it "should error when the status is error" do
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => {status: 'error', message: 'Test Error'}.to_json, :headers => {})

        Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        Biz.errors?.should == true
        Biz.errors.first.should == "ExternalServiceError: Test Error"
      end

      it "should error when the response is malformed and can not find :data key" do
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => {status: 'success'}.to_json, :headers => {})

        Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        Biz.errors?.should == true
        Biz.errors.first.should == "ExternalServiceError: Malformed WMS response object. Can not find :data key"
      end

      it "should error when the response is malformed and can not find :result_list key" do
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => {status: 'success', data: {}}.to_json, :headers => {})

        Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        Biz.errors?.should == true
        Biz.errors.first.should == "ExternalServiceError: Malformed WMS response object. Can not find :result_list key"
      end

      it "should error when the response is malformed and :result_list is not an array" do
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => {status: 'success', data: {result_list: ""}}.to_json, :headers => {})

        Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        Biz.errors?.should == true
        Biz.errors.first.should == "ExternalServiceError: Malformed WMS response object. :result_list is not an array"
      end

      it "should return an array of resources by default" do
        json = {status: 'success', data: {result_list: [{},{},{}]}}.to_json
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => json, :headers => {})

        result = Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        result.kind_of?(Array).should == true
        result.count.should == 3
      end

      it "should return an the first resource if specified" do
        json = {status: 'success', data: {result_list: [{},{},{}]}}.to_json
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => json, :headers => {})

        result = Biz.get(first: 'bam/1/test', query: {foo: 1, bar: 'a'})
        result.class.should == Biz
      end

      it "should return an empty array of resources if none found" do
        json = {status: 'success', data: {result_list: []}}.to_json
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => json, :headers => {})

        result = Biz.get('bam/1/test', query: {foo: 1, bar: 'a'})
        result.kind_of?(Array).should == true
        result.empty?.should == true
      end

      it "should return nil if none found and first is specified" do
        json = {status: 'success', data: {result_list: []}}.to_json
        stub_request(:get, "http://foo.bar/biz/bam/1/test?bar=a&foo=1").
          with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => json, :headers => {})

        result = Biz.get(first: 'bam/1/test', query: {foo: 1, bar: 'a'})
        result.nil?.should == true
      end
    end

  end
end
