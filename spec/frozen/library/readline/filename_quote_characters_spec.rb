require File.dirname(__FILE__) + '/../../spec_helper'

process_is_foreground do

  not_supported_on :ironruby do
    require 'readline'
    describe "Readline.filename_quote_characters" do
      it "needs to be reviewed for spec completeness"
    end

    describe "Readline.filename_quote_characters=" do
      it "needs to be reviewed for spec completeness"
    end
  end
end
