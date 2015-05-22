<% if Rails::VERSION::MAJOR < 3 && Rails::VERSION::MINOR < 2 -%>
require 'safetynet'
<% end -%>
<%= configuration_output %>