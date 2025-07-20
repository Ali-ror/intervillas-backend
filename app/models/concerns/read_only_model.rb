module ReadOnlyModel
  extend ActiveSupport::Concern

  included do
    before_create   { raise ActiveRecord::ReadOnlyRecord }
    before_destroy  { raise ActiveRecord::ReadOnlyRecord }
    before_save     { raise ActiveRecord::ReadOnlyRecord }
    before_update   { raise ActiveRecord::ReadOnlyRecord }
  end

  def readonly?
    true
  end

  def create_or_update
    raise ActiveRecord::ReadOnlyRecord
  end

  def delete
    raise ActiveRecord::ReadOnlyRecord
  end

  module ClassMethods
    def delete_all
      raise ActiveRecord::ReadOnlyRecord
    end

    def destroy_all
      raise ActiveRecord::ReadOnlyRecord
    end
  end
end
