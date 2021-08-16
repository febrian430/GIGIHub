require 'mysql2'
require './models/post'
require './models/user'
require './models/comment'
require './exceptions/not_found'

class CommentController
    def self.create(params)
        attachment = nil
        if params["attachment"]
            attachment = {
                "filename" => params["attachment"]["filename"],
                "mimetype" => params["attachment"]["mimetype"],
                "file" => params["attachment"]["tempfile"]
            }
        end
        comment = Comment.new({
            "body" => params["body"],
            "user_id" => params["user_id"].to_i,
            "post_id" => params["post_id"].to_i,
            "attachment" => attachment
        })

        begin
            return {
                :status => 400,
                :body => {
                    :msg => "post_id and user_id are required"
                }
            } unless comment.save
        rescue NotFoundError
            return {
                :status => 404,
                :body => {
                    :msg => "user or post is not found"
                }
            }
        rescue StandardError => ex
            return {
                :status => 500,
                :body => {
                    :msg => "Error: #{ex.inspect}"
                }
            }
        end
       
        return {
            :status => 201,
            :body => {
                :comment => comment
            }
        }
    end
end