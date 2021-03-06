require 'rails_helper'

Rails.application.config.PAGES_PATH = "#{Rails.root}/spec/pages"

describe MainController do

  let(:page_file) { "#{Rails.application.config.PAGES_PATH}/Page" }
  let(:main_page_file) { "#{Rails.application.config.PAGES_PATH}/#{Rails.application.config.MAIN_PAGE}" }
  let(:content) { 'unparsed content' }
  let(:html_content) { "<p>unparsed content</p>" }

  before do
    File.open(page_file, 'w') { |f| f.write content } unless File.exist? page_file
    File.open(main_page_file, 'w') { |f| f.write 'unparsed main content' } unless File.exist? main_page_file

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials 'user', 'password'
  end

  describe '#show' do
    before { get :show, params }

    context 'Main page' do
      let(:params) { nil }

      it { expect(assigns(:page).to_s).to eq Rails.application.config.MAIN_PAGE }
      it { expect(assigns(:page).title).to eq 'Main page' }
      it { expect(assigns(:page).content).to eq 'unparsed main content' }
      it { expect(assigns(:parsed_content).strip).to eq "<p>unparsed main content</p>" }
      it { expect(response).to render_template(:show) }
    end

    context 'any Page' do
      let(:params) { {page: 'Page'} }

      it { expect(assigns(:page).to_s).to eq 'Page' }
      it { expect(assigns(:page).title).to eq 'Page' }
      it { expect(assigns(:page).content).to eq content }
      it { expect(assigns(:parsed_content).strip).to eq html_content }
      it { expect(response).to render_template(:show) }
    end

    context 'a Page with spaces' do
      let(:params) { {page: 'Page with spaces'} }

      it { expect(assigns(:page).to_s).to eq 'Page_with_spaces' }
      it { expect(assigns(:page).title).to eq 'Page with spaces' }
      it { expect(response).to render_template(:show) }
    end

    context 'an unexisting page' do
      let(:params) { {page: 'unexisting'} }

      it { expect(assigns(:terms)).to eq 'unexisting' }
      it { expect(assigns(:page).to_s).to eq 'unexisting' }
      it { expect(assigns(:page).title).to eq 'unexisting' }
      it { expect(assigns(:page).content).to eq "Page does not exist. Click on the button above to create it." }
      it { expect(assigns(:parsed_content).strip).to eq "<p>Page does not exist. Click on the button above to create it.</p>" }
      it { expect(response).to render_template(:show) }
    end
  end

  describe '#show_all' do
    before { get :show_all, page: Rails.application.config.ALL_PAGE }

    it { expect(assigns(:all_pages)).to eq ['Page'] }
    it { expect(response).to render_template(:show_all) }
  end

  describe '#edit' do
    before { get :edit, params }

    context 'not allowed to edit All' do
      let(:params) { {page: Rails.application.config.ALL_PAGE} }

      it { expect(response).to redirect_to(show_all_path) }
    end

    context 'opening a missing page' do
      let(:params) { {page: 'Missing'} }

      it { expect(assigns(:page).content).to eq '' }
      it { expect(assigns(:parsed_content).strip).to eq '' }
      it { expect(response).to render_template(:edit) }
    end

    context 'opening the page for edition' do
      let(:params) { {page: 'Page'} }

      it { expect(assigns(:page).content).to eq content }
      it { expect(assigns(:parsed_content).strip).to eq html_content }
      it { expect(response).to render_template(:edit) }
    end

    context 'not allowed to update All' do
      let(:params) { {page: Rails.application.config.ALL_PAGE} }

      it { expect(response).to redirect_to(show_all_path) }
    end
  end

  describe '#preview' do
    before { put :preview, page: 'Page', content: content }

    it { expect(assigns(:page).content).to eq content }
    it { expect(assigns(:parsed_content).strip).to eq html_content }
    it { expect(response).to render_template(:edit) }
  end

  describe '#update' do
    before { put :update, page: 'Page', content: content }

    it { expect(response).to redirect_to(show_path('Page')) }
  end

  describe '#delete' do
    before { delete :destroy, params }

    context 'not allowed the deletion of the Main page' do
      let(:params) { {page: Rails.application.config.MAIN_PAGE} }

      it { expect(response).to redirect_to(root_path) }
    end

    context 'delete a page' do
      let(:params) { {page: 'Page'} }

      it { expect(response).to redirect_to(root_path) }
    end
  end

  describe '#search' do
    before { get :search, params }

    context 'search for terms' do
      let(:params) { {terms: 'content'} }

      it { expect(assigns(:terms)).to eq 'content' }
      it { expect(assigns(:page).title).to eq 'Main page' }
      it { expect(response).to render_template(:search) }
    end

    context 'open a new page for creation' do
      let(:params) { {terms: 'content', commit: 'Create'} }

      it { expect(response).to redirect_to(edit_path('content')) }
    end
  end

  describe '#basic_auth' do
    before { request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials 'user', '' }

    it 'rejects access to show' do
      get :show, page: 'Page'
      expect(response.status).to eq 401
    end

    it 'rejects access to show_all' do
      get :show_all, page: Rails.application.config.ALL_PAGE
      expect(response.status).to eq 401
    end

    it 'rejects access to edit' do
      get :edit, page: 'Page'
      expect(response.status).to eq 401
    end

    it 'rejects access to preview' do
      put :preview, page: 'Page'
      expect(response.status).to eq 401
    end

    it 'rejects access to update' do
      put :update, page: 'Page'
      expect(response.status).to eq 401
    end

    it 'rejects access to destroy' do
      delete :destroy, page: 'Page'
      expect(response.status).to eq 401
    end

    it 'rejects access to search' do
      get :search
      expect(response.status).to eq 401
    end
  end
end
