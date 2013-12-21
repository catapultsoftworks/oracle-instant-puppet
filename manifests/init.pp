
class oracle_instant_client{

    if $user == undef { fail("'user' not defined") }

    # VARIABLES
    $oracle_install_path = "/usr/lib/oracle"
    $oracle_source_path = "${oracle_install_path}"
    
    $oracle_repo_root = "https://s3.amazonaws.com/OracleInstantClient" 
    $oracle_basic_filename = "oracle-instantclient11.2-basic-11.2.0.3.0-1.x86_64"
    $oracle_devel_filename = "oracle-instantclient11.2-devel-11.2.0.3.0-1.x86_64"
    $oracle_sqlplus_filename = "oracle-instantclient11.2-sqlplus-11.2.0.3.0-1.x86_64"
    
    $oracle_basic_url = "${oracle_repo_root}/${oracle_basic_filename}.rpm"
    $oracle_devel_url = "${oracle_repo_root}/${oracle_devel_filename}.rpm"
    $oracle_sqlplus_url = "${oracle_repo_root}/${oracle_sqlplus_filename}.rpm"
    
    $ldap_ora_url = "${oracle_repo_root}/ldap.ora"
    $sqlnet_ora_url = "${oracle_repo_root}/sqlnet.ora"
    $tnsnames_url = "${oracle_repo_root}/tnsnames.ora"
    
    $tns_admin_path = "${oracle_install_path}/11.2/client64/network/admin"
    $ld_library_path = "${oracle_install_path}/11.2/client64/lib"
    $oracle_home_path ="${oracle_install_path}/11.2/client64"
    
    # GLOBAL PATH SETTING
    Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

    file {'oracle install directory':
	ensure => 	directory,
	path => 	"${oracle_install_path}",
    }
    ->
    exec { 'ldap.ora':
	command => "wget ${ldap_ora_url} -O ${oracle_source_path}/ldap.ora",
	creates => "${oracle_source_path}/ldap.ora"
    }
    exec { 'sqlnet.ora':
	command => "wget ${sqlnet_ora_url} -O ${oracle_source_path}/sqlnet.ora",
	creates => "${oracle_source_path}/sqlnet.ora"
    }
    ->
    exec { 'tnsnames.ora':
	command => "wget ${tnsnames_url} -O ${oracle_source_path}/tnsnames.ora",
	creates => "${oracle_source_path}/tnsnames.ora"
    }
    exec { 'oracle_basic':
	command => "wget ${oracle_basic_url} -O ${oracle_source_path}/${oracle_basic_filename}.rpm",
	creates => "${oracle_source_path}/${oracle_basic_filename}.rpm"
    }
    ->
    exec { 'oracle_devel':
	command => "wget ${oracle_devel_url} -O ${oracle_source_path}/${oracle_devel_filename}.rpm",
	creates => "${oracle_source_path}/${oracle_devel_filename}.rpm"
    }	
    ->
    exec { 'oracle_sqlplus':
	command => "wget ${oracle_sqlplus_url} -O ${oracle_source_path}/${oracle_sqlplus_filename}.rpm",
	creates => "${oracle_source_path}/${oracle_sqlplus_filename}.rpm"
    }

  # INSTALLATION
  # install client
  exec {"rpm -i ${oracle_install_path}/${oracle_basic_filename}.rpm":
	cwd => 		$oracle_install_path,
	onlyif => 	"test `rpm -qa | grep -c ${oracle_basic_filename}` = '0'",
	logoutput =>	true
  }
  ->
  exec {"rpm -i ${oracle_install_path}/${oracle_sqlplus_filename}.rpm":
	cwd => 		$oracle_install_path,
	onlyif => 	"test `rpm -qa | grep -c ${oracle_sqlplus_filename}` = '0'"
  }
  ->
  exec {"rpm -i ${oracle_install_path}/${oracle_devel_filename}.rpm":
	cwd => 		$oracle_install_path,
	onlyif => 	"test `rpm -qa | grep -c ${oracle_devel_filename}` = '0'"
  }
  ->
  # set some environmental stuff
  file { 'oracle.conf':
	ensure => 	file,
	path => 	"/etc/ld.so.conf.d/oracle.conf",
	content => 	"${ld_library_path}\n"
  }
  ->
  exec {"ldconfig":
	command => 	"ldconfig",
  }
  ->
  file { 'oracle.sh':
	ensure => 	file,
	path => 	"/etc/profile.d/oracle.sh",
	content => 	"export ORACLE_HOME=${oracle_home_path}\n export TNS_ADMIN=${tns_admin_path}\n"
  }
  ->
  file {'oracle home directory':
	ensure => 	directory,
	path => 	"${oracle_home_path}"
  }
  ->
  file {'oracle network directory':
	ensure => 	directory,
	path => 	"${oracle_home_path}/network"
  }
  ->
  file {'oracle network admin directory':
	ensure => 	directory,
	path => 	"${tns_admin_path}"
  }
  ->
  file { 'ldap.ora':
	ensure => 	file,
	path => 	"${tns_admin_path}/ldap.ora",
	source => 	"${oracle_source_path}/ldap.ora"
  }
  ->
  file { 'sqlnet.ora':
	ensure => 	file,
	path => 	"${tns_admin_path}/sqlnet.ora",
	source => 	"${oracle_source_path}/sqlnet.ora"
  }
  ->
  file { 'tnsnames.ora':
	ensure => 	file,
	path => 	"${tns_admin_path}/tnsnames.ora",
	source => 	"${oracle_source_path}/tnsnames.ora"
  }
  ->
  # ENVIRONMENTAL SETTINGS
  exec {"bash -c 'echo \"export PATH=\\\$PATH:${oracle_home_path}/bin\" >> /home/${user}/.bashrc'":
	user => 	$user
  }
  ->
  exec {"bash -c 'echo \"export ORACLE_HOME=${oracle_home_path}\" >> /home/${user}/.bashrc'":
	user => 	$user
  }
  ->
  exec {"bash -c 'echo \"export LD_LIBRARY_PATH=${ld_library_path}\" >> /home/${user}/.bashrc'":
	user => 	$user
  }
  ->
  exec {"bash -c 'echo \"export TNS_ADMIN=${tns_admin_path}\" >> /home/${user}/.bashrc'":
	user => 	$user
  }
}
