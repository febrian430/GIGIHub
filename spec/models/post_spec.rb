require 'rspec'
require './models/post'
require './models/user'
require './models/tag'
require './db/mysql'



describe Post do
    describe "validation before database manipulation" do
        describe "#save?" do
            context "when post body is empty or nil" do
                it "returns false" do
                    post = Post.new({})
                    expect(post.save?).to eq(false)
                end
            end

            context "when the user id is nil" do
                it "returns false" do
                    post = Post.new({"user_id" => nil})
                    expect(post.save?).to eq(false)
                end
            end

            context "when the user id doesnt exist" do
                it "returns false" do
                    post = Post.new({"user_id" => -1})
                    
                    allow(User).to receive(:by_id).and_return(nil)

                    expect(post.save?).to eq(false)
                end
            end

            context "when has body and valid user id" do
                it "returns true" do
                    post = Post.new({
                        "body"=> "abcdefg",
                        "user_id" => 50
                    })
                    user_dbl = double
                    allow(User).to receive(:by_id).and_return(user_dbl)

                    expect(user_dbl).to receive(:nil?).and_return(false)
                    expect(post.save?).to eq(true)
                end
            end
        end
    end

    describe "changes state in the database" do
        describe "#save" do
            context "when not passing #save? validation" do
                it "doesnt call the database and returns false" do
                    post = Post.new({})

                    allow(post).to receive(:save?).and_return(false)
                    expect(post.save).to eq(false)
                end
            end

            context "when passes the database validation with no tags" do
                it "calls the database and returns true" do
                    post = Post.new({
                        "user_id": 1,
                        "body" => "haha aha"
                    })

                    allow(post).to receive(:save?).and_return(true)
                    mock_db = double
                    allow(MySQLDB).to receive(:client).and_return(mock_db)
                    allow(mock_db).to receive(:last_id).and_return(123)

                    expect(mock_db).to receive(:query)
                    expect(post.save).to eq(true)
                end
            end

            context "when passes the database validation with tags" do
                it "calls the database and returns true" do
                    post = Post.new({
                        "user_id": 1,
                        "body" => "ha #ha"
                    })

                    allow(post).to receive(:save?).and_return(true)
                    mock_db = double
                    allow(MySQLDB).to receive(:client).and_return(mock_db)
                    allow(mock_db).to receive(:last_id).and_return(123)

                    expect(Tag).to receive(:insert_post_tags)
                    expect(mock_db).to receive(:query)
                    expect(post.save).to eq(true)
                end
            end

            context "when raw_attachments field is empty" do
                it "doesnt call PostAttachment#attach_to" do
                    post = Post.new({
                        "user_id": 1,
                        "body" => "ha ha"
                    })
                    allow(post).to receive(:save?).and_return(true)
                    mock_db = double
                    allow(MySQLDB).to receive(:client).and_return(mock_db)
                    allow(mock_db).to receive(:query)
                    allow(mock_db).to receive(:last_id).and_return(123)
                    
                    expect(PostAttachment).not_to receive(:attach_to)
                    expect(post.save).to eq(true)
                end
            end

            context "when raw_attachments field is not empty" do
                it "calls PostAttachment#attach_to" do
                    post = Post.new({
                        "user_id": 1,
                        "body" => "ha ha",
                        "attachments" => [
                            {
                                "filename" => "test",
                                "mimetype" => "test"
                            }
                        ]
                    })
                    allow(post).to receive(:save?).and_return(true)
                    mock_db = double
                    allow(MySQLDB).to receive(:client).and_return(mock_db)
                    allow(mock_db).to receive(:query)
                    allow(mock_db).to receive(:last_id).and_return(123)

                    expect(PostAttachment).to receive(:attach_to)
                    expect(post.save).to eq(true)
                end
            end
        end
    end

    describe "fetches" do
        before(:each) do
            @mock_db = double("mock db")
            allow(MySQLDB).to receive(:client).and_return(@mock_db)
        end

        describe "#by_id_exists?" do
            context "when given id doesnt exist" do
                it "returns false" do
                    mock_result = double("query result")
                    allow(@mock_db).to receive(:query).and_return(mock_result)
                    allow(mock_result).to receive(:each).and_return([])

                    expect(Post.by_id_exists?(-1)).to eq(false)
                end
            end

            context "when id exists" do
                it "returns true" do
                    mock_result = double("query result")
                    allow(@mock_db).to receive(:query).and_return(mock_result)
                    allow(mock_result).to receive(:each).and_return([{
                        "id" => 1
                    }])
                        
                    expect(Post.by_id_exists?(-1)).to eq(true)
                end
            end
        end
        
        describe "#by_id" do
            context "when given id doesnt exist" do
                it "returns nil" do
                    mock_result = double("query result")
                    allow(@mock_db).to receive(:query).and_return(mock_result)
                    allow(mock_result).to receive(:each).and_return([])

                    expect(Post.by_id(-1)).to eq(nil)
                end
            end

            context "when id exists" do
                it "returns the post" do
                    mock_result = double("query result")
                    allow(@mock_db).to receive(:query).and_return(mock_result)
                    allow(mock_result).to receive(:each).and_return([{
                        "id" => "1",
                        "body" => "123",
                        "created_at" => "1111111",
                        "user_id" => "1"
                    }])
                        
                    expect(Post.by_id(-1)).not_to eq(nil)
                end
            end
        end

        describe "#all" do
            before(:each) do
                @mock_result = double("query result")
                allow(@mock_db).to receive(:query).and_return(@mock_result)
                allow(@mock_result).to receive(:each).and_return([{
                    "id" => "1",
                    "body" => "123",
                    "created_at" => "1111111",
                    "user_id" => "1"
                }, 
                {
                    "id" => "2",
                    "body" => "dd",
                    "created_at" => "555",
                    "user_id" => "2"
                }])
            end
            context "when given empty filter" do
                it "returns all posts sorted by the most recent posts" do
                    

                    posts = Post.all({})
                    # puts posts[0].inspect
                    expect(posts).not_to eq([])
                    expect(posts[0].instance_of? Post).to be_truthy
                end
            end

            context "when given tag filter" do
                it "returns filtered posts sorted by the most recent posts" do
                    

                    posts = Post.all({
                        "tag" => "sOmE_tAg"
                    })
                    # puts posts[0].inspect
                    expect(posts).not_to eq([])
                    expect(posts[0].instance_of? Post).to be_truthy
                end
            end
        end
    end
end