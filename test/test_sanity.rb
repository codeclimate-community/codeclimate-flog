require "minitest/autorun"
require "cc/engine/flog"

class TestSanity < Minitest::Test
  def config subconfig = nil
    base = {
            "enabled"       => true,
            "include_paths" => ["."],
           }
    if subconfig then
      base.merge "config" => subconfig
    else
      base
    end
  end

  def assert_init exp_all, cfg = nil
    root = "."
    exp = ["./lib/cc/engine/flog.rb", "./test/test_sanity.rb"]
    ccflog = CC::Engine::Flog.new(root, config(cfg))
    assert_equal exp_all, ccflog.config["all"]
    assert_equal exp, ccflog.files

    exp_conf = {
                "include_paths" => ["."],
                "all" => exp_all,
               }
    assert_equal exp_conf, ccflog.config

  end

  def test_initialize_cc_bugs
    # https://github.com/codeclimate/codeclimate-yaml/issues/38
    # https://github.com/codeclimate/codeclimate-yaml/issues/39

    assert_init false                   # no config--expected and good
    assert_init true,  "all" => true    # true config
    assert_init true,  "all" => "true"  # buggy "true" config
    assert_init false, "all" => false   # false config
    assert_init false, "all" => "false" # buggy "false" config
    assert_init false, ""               # buggy "" config
  end
end
