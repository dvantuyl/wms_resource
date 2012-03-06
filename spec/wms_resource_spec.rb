#require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'spec_helper'

describe WmsResource do
  it "should have a base_url" do
    base_url = "http://foo.bar"

    WmsResource.base_url = base_url
    WmsResource.base_url.should == base_url
  end
end
