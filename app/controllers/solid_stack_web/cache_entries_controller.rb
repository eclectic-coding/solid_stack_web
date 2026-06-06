module SolidStackWeb
  class CacheEntriesController < ApplicationController
    def index
      @search = params[:q].presence
      @sort   = resolve_sort

      scope = ::SolidCache::Entry.all
      scope = scope.where("key LIKE ?", "%#{::ActiveRecord::Base.sanitize_sql_like(@search)}%") if @search
      scope = scope.order(@sort["column"] => @sort["direction"])

      @pagy, @entries = pagy(scope)
    end

    def show
      @entry = ::SolidCache::Entry.find(params[:id])
    end

    def destroy
      ::SolidCache::Entry.find(params[:id]).destroy
      redirect_to cache_entries_path(q: params[:q], column: params[:column], direction: params[:direction]),
                  notice: t("solid_stack_web.flash.cache_entry_deleted")
    end

    private

    def resolve_sort
      column    = %w[byte_size created_at key].include?(params[:column]) ? params[:column] : "byte_size"
      direction = %w[asc desc].include?(params[:direction])              ? params[:direction] : "desc"
      { "column" => column, "direction" => direction }
    end
  end
end
