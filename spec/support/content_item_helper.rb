module ContentItemHelpers

  def stub_call_to_content_store(content_store_url, web_url)
    stub_request(:get, content_store_url).to_return(body: content_item('my_url'))
  end

  def content_item(web_url)
    {
      "base_path" => "/government/policies/2012-olympic-and-paralympic-legacy/email-signup",
      "content_id"=>"404e4ebc-d413-44d6-b157-b70c118397d3",
      "title"=>"2012 Olympic and Paralympic legacy",
      "description"=>"",
      "format"=>"email_alert_signup",
      "need_ids"=>[],
      "locale"=>"en",
      "updated_at"=>"2015-11-05T13:06:52.413Z",
      "public_updated_at"=>"2015-05-26T15:15:26.742+00:00",
      "details"=>{
        "breadcrumbs"=> [
          {
            "title"=>"2012 Olympic and Paralympic legacy",
            "link"=>"/government/policies/2012-olympic-and-paralympic-legacy"
          }
        ],
        "summary"=>"\n      You'll get an email each time a document about\n      this policy is published or updated.\n    ",
        "tags"=>{
          "policy"=>[
            "2012-olympic-and-paralympic-legacy"
          ]
        },
        "govdelivery_title"=>"2012 Olympic and Paralympic legacy policy"
      },
      "phase"=>"live",
      "analytics_identifier"=>nil,
      "links"=>{
        "parent"=>[
          {
            "content_id"=>"5d37821b-7631-11e4-a3cb-005056011aef",
            "title"=>"2012 Olympic and Paralympic legacy",
            "base_path"=>"/government/policies/2012-olympic-and-paralympic-legacy",
            "description"=>"",
            "api_url"=>"https://www.gov.uk/api/content/government/policies/2012-olympic-and-paralympic-legacy",
            "web_url"=> web_url,
            "locale"=>"en"
          }
        ],
        "available_translations"=>[
          {
            "content_id"=>"404e4ebc-d413-44d6-b157-b70c118397d3",
            "title"=>"2012 Olympic and Paralympic legacy",
            "base_path"=>"/government/policies/2012-olympic-and-paralympic-legacy/email-signup",
            "description"=>"",
            "api_url"=>"https://www.gov.uk/api/content/government/policies/2012-olympic-and-paralympic-legacy/email-signup",
            "web_url"=>"https://www.gov.uk/government/policies/2012-olympic-and-paralympic-legacy/email-signup",
            "locale"=>"en"
          }
        ]
      }
    }.to_json
  end
end
