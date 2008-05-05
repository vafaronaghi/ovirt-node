# 
# Copyright (C) 2008 Red Hat, Inc.
# Written by Darryl L. Pierce <dpierce@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

# +LDAPConnection+ handles establishing, returning and closing
# connections with an LDAP server.
#
class LDAPConnection
  @@hostname = nil
  @@port = 389
   
  # Connects the LDAP server. 
  def LDAPConnection.connect(
			     base,
			     hostname = LDAPConnection.hostname, 
			     port = LDAPConnection.port
			     )
    ActiveLdap::Base.establish_connection(:host => hostname
  end

  # Returns whether a connection already exists to the LDAP server.
  def LDAPConnection.connected?
    return ActiveLdap::Base.connected?
  end

  # Disconnects from the LDAP server.
  def LDAPConnection.disconnected
    ActiveLdap::Base.remove_connection if LDAPConnection.connected?
  end

end
