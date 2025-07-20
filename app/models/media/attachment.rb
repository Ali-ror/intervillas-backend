module Media::Attachment
  extend ActiveSupport::Concern

  included do
    class_attribute :media_attachment_name,
      instance_predicate: false,
      instance_writer:    false

    after_save :update_attachment_filename,
      if: :media_attachment_name
  end

  def attach_media(attachable)
    media_attachment.attach(attachable)
  end

  def attachment_present?
    media_attachment.attached?
  end

  def filename
    media_attachment.filename.sanitized
  end

  def filename=(val) # rubocop:disable Rails/Delegate
    media_attachment.filename = val
  end

  def filename_without_extension
    name = Pathname.new(filename).sub_ext("").to_s.gsub(/[.\W]+/, "_")
    name.blank? || name.start_with?(".") ? "image" : name
  end

  def blob_id
    media_attachment.blob.key
  end

  private

  def media_attachment
    public_send(media_attachment_name)
  end

  def update_attachment_filename
    media_attachment.blob.save if attachment_present? && media_attachment.blob.filename_changed?
  end

  module ClassMethods
    def attach_media(attachment_name)
      has_one_attached attachment_name             # bind to ActiveStorage
      self.media_attachment_name = attachment_name # save name for helper methods
    end
  end
end
