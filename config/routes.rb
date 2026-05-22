SolidStackWeb::Engine.routes.draw do
  root to: "queue/jobs#index"

  scope :queue, as: :queue do
    root to: "queue/jobs#index", as: :root
  end

  scope :cache, as: :cache do
    root to: "cache/entries#index", as: :root
  end

  scope :cable, as: :cable do
    root to: "cable/messages#index", as: :root
  end
end
