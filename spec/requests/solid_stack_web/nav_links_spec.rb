require "rails_helper"

RSpec.describe "Nav links", type: :request do
  let(:engine_root) { "/solid_stack" }

  after { SolidStackWeb.nav_links = nil }

  it "renders no custom links by default" do
    get engine_root
    expect(response.body).not_to include("sqw-nav__link--custom")
  end

  it "renders a configured custom nav link" do
    SolidStackWeb.nav_links = [{ label: "Admin", url: "/admin" }]
    get engine_root
    expect(response.body).to include("Admin")
    expect(response.body).to include("/admin")
  end

  it "renders multiple custom nav links" do
    SolidStackWeb.nav_links = [
      { label: "Admin", url: "/admin" },
      { label: "Docs",  url: "/docs"  }
    ]
    get engine_root
    expect(response.body).to include("Admin")
    expect(response.body).to include("/admin")
    expect(response.body).to include("Docs")
    expect(response.body).to include("/docs")
  end

  it "renders custom links with the nav link class" do
    SolidStackWeb.nav_links = [{ label: "Admin", url: "/admin" }]
    get engine_root
    expect(response.body).to match(/class="sqw-nav__link"[^>]*>Admin/)
  end
end
