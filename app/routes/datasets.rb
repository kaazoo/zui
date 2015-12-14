class ZUI < Sinatra::Application

  # Show the specified dataset,
  # represented by its full path
  get '/:pool/*/' do |pool, path|
    # Ignore if no path was given
    pass if path.empty?

    full_path = File.join(pool, path)
    @selected = full_path
    @dataset = ZFS(full_path)

    halt 404 unless @dataset.exist?
    erb :'datasets/show', layout: !request.xhr?
  end

  # Render the New dataset form
  get '/dataset/new' do
    # FIXME: hack to bypass the before filter
    @pools = ZFS.pools if request.xhr?

    erb :'datasets/new', layout: !request.xhr?
  end

  # Create a new dataset
  post '/dataset/new' do
    name = params[:name]
    size = params[:size]
    path = params[:path]
    type = params[:type]

    # Validate fields
    if name.empty? || path.empty?
      flash[:error] = 'The name cannot be empty.'
      redirect back
    end

    # Try creating the dataset
    begin
      dataset = ZFS(File.join(path, name), type)
      dataset.create!({ parents: true, size: size, type: type })
    rescue ZFS::Error => e
      flash[:error] = e.message
      redirect back
    end

    # Success
    flash[:ok] = "#{type} '#{dataset.name}' created successfully!"
    redirect back
  end

  # Update dataset properties
  put '/dataset/*/' do |path|
    dataset = ZFS(path)
    halt 404, 'dataset does not exist' unless dataset.exist?

    # FIXME: Error handling?
    if params[:compression]
      # Use LZ4 as the default compression algorithm
      dataset.compression = (params[:compression] == '1') ? 'lz4' : false
    end

    if params[:deduplication]
      dataset.dedup = (params[:deduplication] == '1')
    end

    if params[:readonly]
      dataset.readonly = (params[:readonly] == '1')
    end

    redirect to("/#{dataset.uid}/")
  end

  # Destroy a dataset
  delete '/:pool/*/' do |pool, path|
    dataset = ZFS(File.join(pool, path))
    halt 404, 'dataset does not exist' unless dataset.exist?

    # Try destroying the dataset and all its children
    begin
      dataset.destroy!({ children: true })
    rescue ZFS::Error => e
      # FIXME: handle errors
      puts e.message
    end

    redirect to('/')
  end

end