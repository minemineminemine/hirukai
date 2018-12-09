Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/main' => 'tops#main', as: 'main'
  get '/' => 'tops#top', as: 'top'
  get '/scrape' => 'tops#scrape', as: 'scrape'
  get "rests/:id/edit" => "tops#edit_rest",as: "rest_edit"
  patch "rests/edit" => "tops#rest_update",as: "rest_update"
  get "qa/edit" => "tops#edit_qa", as: "qa_edit"
  patch "qa/edit" => "tops#update_qa",as: "qa_update"
  get "qa/:id" => "tops#delete_qa", as: "qa_delete"
  post "qa/edit" => "tops#add_qa", as: "qa_add"
end
