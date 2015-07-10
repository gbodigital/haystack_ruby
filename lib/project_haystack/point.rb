require 'date'
# require 'active_support'
module ProjectHaystack
  module Point
    # extend ::ActiveSupport::Concern
    # attr_accessible :haystack_project_name, :haystack_point_id
    # haystack_project_name, :haystack_point_id are required where this module is mixed in

    def haystack_project
      @project ||= ProjectHaystack::Config.projects[@haystack_project_name]
    end

    def connection
      haystack_project.connection
    end

    def his_read(range)
      query = ["ver:\"#{haystack_project.haystack_version}\"",'id,range',"#{haystack_point_id},\"#{range}\""]
      pp query.join "\n"
      res = connection.post('hisRead') do |req|
        req.headers['Content-Type'] = 'text/plain'
        req.body = query.join("\n")
      end
      JSON.parse! res.body
    end

    def meta
      # TODO set / refresh haystack_time_zone from the tx in returned data
      # read request on project to load current info, including tags and timezone
      res = haystack_project.read({:id => haystack_point_id})['rows'].first
    end

    def data(range)
      # clean up the range argument before passing through to hisRead
      # ----------------
      r = ProjectHaystack::Range.new(range, @haystack_time_zone)
  
      res = his_read r.to_s
      reformat_timeseries(res['rows'])
    end

    # map from 
    def reformat_timeseries data
      data.map do |d|
        # may not keep unit
        {:time => DateTime.parse(d['ts']).to_time.to_i, :value => d['val'], :unit => ['val.unit']}
      end
    end
  end
end