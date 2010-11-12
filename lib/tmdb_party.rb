require 'httparty'

%w[core_extensions httparty_icebox attributes video genre person image country studio cast_member movie].each do |class_name|
  require "tmdb_party/#{class_name}"
end

module TMDBParty
  class Base
    include HTTParty
    include HTTParty::Icebox
    cache :store => 'file', :timeout => 120, :location => Dir.tmpdir

    base_uri 'http://api.themoviedb.org/2.1'
    format :json
    
    def initialize(key, lang = 'en')
      @api_key = key
      @lang = lang
    end
    
    def search(query)
      puts method_url('Movie.search', query)
      data = self.class.get(method_url('Movie.search', query)).parsed_response
      if data.class != Array || data.first == "Nothing found."
        []
      else
        data.collect { |movie| Movie.new(movie, self) }
      end
    end
    
    # query_hash holds optional parameters.
    # E.g. {
    #  'genres' => 28,
    #  'per_page' => 10,
    #  'page' => 1,    
    # }
    # Full list at http://api.themoviedb.org/2.1/methods/Movie.browse
    def browse(query_hash)
      query_string = ""
      query_hash.each do |key, value|
        query_string += key + "=" + value.to_s + "&"
      end
      data = self.class.get(method_url('Movie.browse', query_string)).parsed_response
      if data.class != Array || data.first == "Nothing found."
        []
      else
        data.collect { |movie| Movie.new(movie, self) }
      end
    end
    
    def search_person(query)
      data = self.class.get(method_url('Person.search', query)).parsed_response
      if data.class != Array || data.first == "Nothing found."
        []
      else
        data.collect { |person| Person.new(person, self) }
      end
    end
    
    def imdb_lookup(imdb_id)
      data = self.class.get(method_url('Movie.imdbLookup', imdb_id)).parsed_response
      if data.class != Array || data.first == "Nothing found."
        nil
      else
        Movie.new(data.first, self)
      end
    end
    
    def get_info(id)
      data = self.class.get(method_url('Movie.getInfo', id)).parsed_response
      Movie.new(data.first, self)
    end
    
    def get_person(id)
      data = self.class.get(method_url('Person.getInfo', id)).parsed_response
      Person.new(data.first, self)
    end
    
    private
      def default_path_items
        # [@lang, 'json', @api_key]
        [@lang, 'json']
      end
      
      def api_key
        @api_key
      end
      
      def method_url(method, value)
        if method == 'Movie.browse'
          # Use '?' after api_key rather than '/' (causes 401 HTTP unauthorized for Movie.browse)
          '/' + ([method] + default_path_items).join('/') + '/' + api_key.to_s + '?' + ([URI.escape(value.to_s)]).join('/')
        else
          '/' + ([method] + default_path_items + [api_key] + [URI.escape(value.to_s)]).join('/')
        end
      end
  end
end
