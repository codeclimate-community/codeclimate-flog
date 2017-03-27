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

  def assert_init exp_score_threshold, cfg = nil
    root = "."
    exp = ["./lib/cc/engine/flog.rb", "./test/test_sanity.rb"].sort
    ccflog = CC::Engine::Flog.new(root, config(cfg))
    assert_equal exp_score_threshold, ccflog.config["score_threshold"]
    assert_equal exp, ccflog.files.sort

    exp_conf = {
                "include_paths" => ["."],
                "score_threshold" => exp_score_threshold,
               }
    assert_equal exp_conf, ccflog.config

  end

  def test_initialize_cc_bugs
    # https://github.com/codeclimate/codeclimate-yaml/issues/38
    # https://github.com/codeclimate/codeclimate-yaml/issues/39

    assert_init 20.0                              # no config--expected and good
    assert_init 17.5, "score_threshold" => "17.5" # coercing string to float
    assert_init 20.0, ""                          # buggy "" config
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
