require 'json'
require './models/user'
require './models/post'
require './utils/response'

class PostController

    def self.create(params)
        attachments = []
        if params["attachments"]
            attachments = params["attachments"].map {
                |data|
                {
                    "filename" => data["filename"],
                    "mimetype" => data["type"],
                    "file" => data["tempfile"]
                }
            } 
        end

        if params["body"] && (params["body"].length > 1000)
            return {
                :status => 400,
                :body => {
                    :msg => "body has more than 1000 characters"
                }
            }
        end

        post = Post.new({
            "user_id" => params["user_id"].to_i,
            "body" => params["body"],
            "attachments" => attachments
        })

        user = User.by_id(post.user_id)
        return DefaultResponse.not_found unless user
        
        return DefaultResponse.internal_server_error unless post.save


        response = DefaultResponse.created
        response[:body] = {
            :post => post
        }
        return response
    end

    def self.show_by_id(params)
        post = Post.by_id(params["id"].to_i)
        return DefaultResponse.not_found unless post

        response = {
            :status => 200,
            :body => {
                :post => post
            }
        }
        return response
    end

    def self.find(params)
        posts = Post.all({
            "tag" => params["tag"]
        })
        response = {
            :status => 200,
            :body => {
                :posts => posts
            }
        }
    end
end