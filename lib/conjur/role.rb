module Conjur
  class Role < RestClient::Resource
    include Exists
    include PathBased

    def identifier
      match_path(2..-1)
    end
    
    alias id identifier
    
    def create(options = {})
      log do |logger|
        logger << "Creating role #{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end
    
    def all(options = {})
      JSON.parse(self["?all"].get(options)).collect do |id|
        Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape id}?all", self.options)
      end
    end
    
    def grant_to(member, admin_option = false, options = {})
      self.members.grant_to member, admin_option, options
      log do |logger|
        logger << "Granting role #{identifier} to #{member}"
        if admin_option
          logger << " with admin option"
        end
        unless options.empty?
          logger << " and extended options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}&admin_option=#{query_escape admin_option}"].put(options)
    end

    def revoke_from(member, options = {})
      log do |logger|
        logger << "Revoking role #{identifier} from #{member}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}"].delete(options)
    end

    def permitted?(resource_kind, resource_id, privilege, options = {})
      self["?check&resource_kind=#{query_escape resource_kind}&resource_id=#{query_escape resource_id}&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
    
    def members
      Role.new(Conjur::Authz::API.host, credentials)[role_path(role)]
    end
  end
end