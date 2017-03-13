require "minitest/autorun"
require "cc/engine/flog"
require "json" # comes in from code climate, but needed for tests

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
    exp = ["./test/test_sanity.rb", "./lib/cc/engine/flog.rb"]
    ccflog = CC::Engine::Flog.new(root, config(cfg))
    assert_equal exp_all, ccflog.config["all"]
    assert_equal exp, ccflog.files

    exp_conf = {
                "include_paths" => ["."],
                "all" => exp_all,
               }

    if cfg && cfg["threshold"]
      exp_conf.merge! "threshold" => cfg["threshold"].to_f
    end

    assert_equal exp_conf, ccflog.config
  end

  def test_initialize_cc_bugs
    # https://github.com/codeclimate/codeclimate-yaml/issues/38
    # https://github.com/codeclimate/codeclimate-yaml/issues/39

    assert_init true                    # no config--expected and good
    assert_init false,  "all" => false  # false config
    assert_init true,  "all" => "true"  # buggy "true" config
    assert_init false, "all" => false   # false config
    assert_init false, "all" => "false" # buggy "false" config
    assert_init false, "all" => "false",
      "threshold" => "0.8"              # buggy float config
    assert_init true, ""                # buggy "" config
  end

  def test_run
    root = "."
    io = StringIO.new
    ccflog = CC::Engine::Flog.new(root, config, io)

    ccflog.run

    io.rewind
    issues = io.read.split("\0").map { |issue| JSON.parse(issue) }

    issue = issues.detect { |i| i["description"].include?("Flog#run") }

    assert_kind_of  Hash,                      issue
    assert_equal    "issue",                   issue["type"]
    assert_equal    "Flog Score",              issue["check_name"]
    assert_equal    ["Complexity"],            issue["categories"]
    assert_includes issue["content"]["body"],  "ABC score"
    assert_kind_of  Numeric,                   issue["remediation_points"]
    assert_kind_of  String,                    issue["fingerprint"]
    assert_equal    "./lib/cc/engine/flog.rb", issue["location"]["path"]
    assert_kind_of  Integer,                   issue["location"]["lines"]["begin"]
    assert_kind_of  Integer,                   issue["location"]["lines"]["end"]
  end
end
