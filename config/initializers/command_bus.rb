# Handlers register themselves on the bus when their class body runs, so they
# all need loading up front. Autoloading alone would miss the ones nothing
# else references yet.
Rails.application.config.to_prepare do
  Rails.autoloaders.main.eager_load_dir(Rails.root.join("app/domain"))
end
