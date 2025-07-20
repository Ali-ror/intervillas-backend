json.array! images do |img|
  json.extract! img,
    :id,
    :status,
    :version

  json.thumbnail media_path(img.medium, preset: :admin_thumb)
end
