require "path_expander"
require "flog"
require "digest/md5"

module CC
  module Engine
    class Flog
      VERSION = "1.0.0"

      # TODO: non-methods (ie, attrs/scopes/relations) have no location, skipped
      # TODO: possibly scale remediation score exponentially
      # TODO: XXX#main is locationless. improve flog to report first sighting?
      # TODO: possibly add score to fingerprint?
      # TODO: Finish running through the QA spreadsheet

      attr_accessor :dir
      attr_accessor :config
      attr_accessor :io
      attr_accessor :flog
      attr_accessor :files

      DEFAULTS = {
                  "include_paths"   => ["."],
                  "score_threshold" => 20.0,
                 }

      def initialize(root, config = {}, io = STDOUT)
        self.dir    = root
        self.config = config = normalize_conf(config)
        self.io     = io

        options = {
                   :all       => true,
                   :continue  => true,
                  }

        self.flog   = ::Flog.new(options)

        paths = config["include_paths"].dup
        expander = PathExpander.new(paths, "**/*.{rb,rake}")
        self.files = expander.process.select { |s| s =~ /\.(?:rb|rake)$/ }
      end

      ##
      # The resulting config coming from codeclimate and/or docker is
      # pretty mangled. It isn't actually parsing yaml properly and
      # this deals with that.
      #
      # https://github.com/codeclimate/codeclimate-yaml/issues/38
      # https://github.com/codeclimate/codeclimate-yaml/issues/39

      def normalize_conf(top_config)
        # fix the top, if necessary
        top_config = reparse(top_config)
        top_config["config"] ||= {}

        # normalize contents
        config = DEFAULTS.merge(top_config["config"])
        config["include_paths"] = top_config["include_paths"] if
          top_config["include_paths"]

        config
      end

      ##
      # .codeclimate.yml is not parsed by a YAML compliant library and
      # values come back incorrect. Specifically, nil => "", false =>
      # "false" break a lot of logic. This method reparses the values,
      # recursively if necessary.

      def reparse(val)
        require "yaml"
        case val
        when String then
          YAML.safe_load(val)
        when Array then
          val.map { |v| reparse(v) }
        when Hash then
          Hash[val.map { |k, v| [reparse(k), reparse(v)] }]
        else
          val
        end
      end

      ##
      # Run flog and print issues as they come up.

      def run
        Dir.chdir(dir) do
          flog.flog(*files)

          flog.each_by_score do |name, score, call_list|
            location = flog.method_locations[name]

            next unless location # XXX#main is location-less, skip for now
            next unless score > config["score_threshold"]

            datum = "Complex method %s (%.1f)" % [name, score]
            issue = self.issue(name, datum, location, score)

            if issue then
              io.print issue.to_json
              io.print "\0"
            end
          end
        end
      end

      CONTENT = <<~END
        Flog calculates the ABC score for methods.
        The ABC score is based on assignments, branches (method calls), and conditions.

        You can read more about [ABC metrics](http://c2.com/cgi/wiki?AbcMetric) or
        [the flog tool](http://www.zenspider.com/projects/flog.html)
      END
      BASE_REMEDIATION_POINTS = 200_000
      OVERAGE_REMEDIATION_POINTS = 50_000

      ##
      # Create an issue hash from +name+, +datum+, +location+, and +score+.

      def issue(name, datum, location, score)
        file, l_start, l_end = [$1, $2.to_i, $3.to_i] if
          location =~ /^(.+?):(\d+)-(\d+)$/

        unless file && l_start && l_end then
          warn "Couldn't parse location %p for %p" % [location, name]
          return
        end


        remediation_points = (BASE_REMEDIATION_POINTS + (OVERAGE_REMEDIATION_POINTS * (score - config["score_threshold"]))).
          round

        {
         "type"        => "issue",
         "check_name"  => "Flog Score",
         "description" => datum,
         "categories"  => ["Complexity"],
         "content"     => { "body" => CONTENT },
         "remediation_points" => remediation_points,
         "fingerprint" => Digest::MD5.hexdigest(name),
         "location"    => {
                           "path"  => file,
                           "lines" => {"begin" => l_start, "end" => l_end}
                          }
        }
      end
    end
  end
end
