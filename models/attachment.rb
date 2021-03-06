require './models/model'
require './utils/storage_manager'

class Attachment < Model
    def initialize(params)
        @id = params["id"].to_i
        @filename = params["filename"]
        @mimetype = params["mimetype"]
        host = ENV["HOST"]
        if ENV["MODE"] == "PROD"
            host = ENV["PROD_APP_HOST"]
        end
        @filepath = "http://#{host}:#{ENV["PORT"]}/static/#@filename" 
        @showable_variables = ["id", "filename", "mimetype", "filepath"]

    end

    def self.attach_to(obj, files = [])
        raise NotImplementedError
    end
    
    def self.store_files(files = [])
        StorageManager.store(files)
    end

    def self.build_insert_query(obj, files)
        raise NotImplementedError
    end

    private_class_method :build_insert_query
end