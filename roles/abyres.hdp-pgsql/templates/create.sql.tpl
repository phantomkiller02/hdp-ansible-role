--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
CREATE DATABASE :dbname;
\connect :dbname;

ALTER ROLE :username LOGIN ENCRYPTED PASSWORD :password;
CREATE ROLE :username LOGIN ENCRYPTED PASSWORD :password;

GRANT ALL PRIVILEGES ON DATABASE :dbname TO :username;

CREATE SCHEMA ambari AUTHORIZATION :username;
ALTER SCHEMA ambari OWNER TO :username;
ALTER ROLE :username SET search_path TO 'ambari';

------create tables and grant privileges to db user---------
CREATE TABLE ambari.stack(
  stack_id BIGINT NOT NULL,
  stack_name VARCHAR(255) NOT NULL,
  stack_version VARCHAR(255) NOT NULL,
  CONSTRAINT PK_stack PRIMARY KEY (stack_id),
  CONSTRAINT UQ_stack UNIQUE (stack_name, stack_version)
);
GRANT ALL PRIVILEGES ON TABLE ambari.stack TO :username;

CREATE TABLE ambari.extension(
  extension_id BIGINT NOT NULL,
  extension_name VARCHAR(255) NOT NULL,
  extension_version VARCHAR(255) NOT NULL,
  CONSTRAINT PK_extension PRIMARY KEY (extension_id),
  CONSTRAINT UQ_extension UNIQUE(extension_name, extension_version));
GRANT ALL PRIVILEGES ON TABLE ambari.extension TO :username;

CREATE TABLE ambari.extensionlink(
  link_id BIGINT NOT NULL,
  stack_id BIGINT NOT NULL,
  extension_id BIGINT NOT NULL,
  CONSTRAINT PK_extensionlink PRIMARY KEY (link_id),
  CONSTRAINT FK_extensionlink_stack_id FOREIGN KEY (stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT FK_extensionlink_extension_id FOREIGN KEY (extension_id) REFERENCES ambari.extension(extension_id),
  CONSTRAINT UQ_extension_link UNIQUE(stack_id, extension_id));
GRANT ALL PRIVILEGES ON TABLE ambari.extensionlink TO :username;

CREATE TABLE ambari.adminresourcetype (
  resource_type_id INTEGER NOT NULL,
  resource_type_name VARCHAR(255) NOT NULL,
  CONSTRAINT PK_adminresourcetype PRIMARY KEY (resource_type_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.adminresourcetype TO :username;

CREATE TABLE ambari.adminresource (
  resource_id BIGINT NOT NULL,
  resource_type_id INTEGER NOT NULL,
  CONSTRAINT PK_adminresource PRIMARY KEY (resource_id),
  CONSTRAINT FK_resource_resource_type_id FOREIGN KEY (resource_type_id) REFERENCES ambari.adminresourcetype(resource_type_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.adminresource TO :username;

CREATE TABLE ambari.clusters (
  cluster_id BIGINT NOT NULL,
  resource_id BIGINT NOT NULL,
  upgrade_id BIGINT,
  cluster_info VARCHAR(255) NOT NULL,
  cluster_name VARCHAR(100) NOT NULL UNIQUE,
  provisioning_state VARCHAR(255) NOT NULL DEFAULT 'INIT',
  security_type VARCHAR(32) NOT NULL DEFAULT 'NONE',
  desired_cluster_state VARCHAR(255) NOT NULL,
  desired_stack_id BIGINT NOT NULL,
  CONSTRAINT PK_clusters PRIMARY KEY (cluster_id),
  CONSTRAINT FK_clusters_desired_stack_id FOREIGN KEY (desired_stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT FK_clusters_resource_id FOREIGN KEY (resource_id) REFERENCES ambari.adminresource(resource_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.clusters TO :username;

CREATE TABLE ambari.clusterconfig (
  config_id BIGINT NOT NULL,
  version_tag VARCHAR(255) NOT NULL,
  version BIGINT NOT NULL,
  type_name VARCHAR(255) NOT NULL,
  cluster_id BIGINT NOT NULL,
  stack_id BIGINT NOT NULL,
  config_data TEXT NOT NULL,
  config_attributes TEXT,
  create_timestamp BIGINT NOT NULL,
  CONSTRAINT PK_clusterconfig PRIMARY KEY (config_id),
  CONSTRAINT FK_clusterconfig_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id),
  CONSTRAINT FK_clusterconfig_stack_id FOREIGN KEY (stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT UQ_config_type_tag UNIQUE (cluster_id, type_name, version_tag),
  CONSTRAINT UQ_config_type_version UNIQUE (cluster_id, type_name, version)
);
GRANT ALL PRIVILEGES ON TABLE ambari.clusterconfig TO :username;

CREATE TABLE ambari.clusterconfigmapping (
  cluster_id BIGINT NOT NULL,
  type_name VARCHAR(255) NOT NULL,
  version_tag VARCHAR(255) NOT NULL,
  create_timestamp BIGINT NOT NULL,
  selected INTEGER NOT NULL DEFAULT 0,
  user_name VARCHAR(255) NOT NULL DEFAULT '_db',
  CONSTRAINT PK_clusterconfigmapping PRIMARY KEY (cluster_id, type_name, create_timestamp),
  CONSTRAINT clusterconfigmappingcluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.clusterconfigmapping TO :username;

CREATE TABLE ambari.serviceconfig (
  service_config_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  version BIGINT NOT NULL,
  create_timestamp BIGINT NOT NULL,
  stack_id BIGINT NOT NULL,
  user_name VARCHAR(255) NOT NULL DEFAULT '_db',
  group_id BIGINT,
  note TEXT,
  CONSTRAINT PK_serviceconfig PRIMARY KEY (service_config_id),
  CONSTRAINT FK_serviceconfig_stack_id FOREIGN KEY (stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT UQ_scv_service_version UNIQUE (cluster_id, service_name, version)
);
GRANT ALL PRIVILEGES ON TABLE ambari.serviceconfig TO :username;

CREATE TABLE ambari.hosts (
  host_id BIGINT NOT NULL,
  host_name VARCHAR(255) NOT NULL,
  cpu_count INTEGER NOT NULL,
  ph_cpu_count INTEGER,
  cpu_info VARCHAR(255) NOT NULL,
  discovery_status VARCHAR(2000) NOT NULL,
  host_attributes VARCHAR(20000) NOT NULL,
  ipv4 VARCHAR(255),
  ipv6 VARCHAR(255),
  public_host_name VARCHAR(255),
  last_registration_time BIGINT NOT NULL,
  os_arch VARCHAR(255) NOT NULL,
  os_info VARCHAR(1000) NOT NULL,
  os_type VARCHAR(255) NOT NULL,
  rack_info VARCHAR(255) NOT NULL,
  total_mem BIGINT NOT NULL,
  CONSTRAINT PK_hosts PRIMARY KEY (host_id),
  CONSTRAINT UQ_hosts_host_name UNIQUE (host_name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.hosts TO :username;

CREATE TABLE ambari.serviceconfighosts (
  service_config_id BIGINT NOT NULL,
  host_id BIGINT NOT NULL,
  CONSTRAINT PK_serviceconfighosts PRIMARY KEY (service_config_id, host_id),
  CONSTRAINT FK_scvhosts_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts(host_id),
  CONSTRAINT FK_scvhosts_scv FOREIGN KEY (service_config_id) REFERENCES ambari.serviceconfig(service_config_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.serviceconfighosts TO :username;

CREATE TABLE ambari.serviceconfigmapping (
  service_config_id BIGINT NOT NULL,
  config_id BIGINT NOT NULL,
  CONSTRAINT PK_serviceconfigmapping PRIMARY KEY (service_config_id, config_id),
  CONSTRAINT FK_scvm_config FOREIGN KEY (config_id) REFERENCES ambari.clusterconfig(config_id),
  CONSTRAINT FK_scvm_scv FOREIGN KEY (service_config_id) REFERENCES ambari.serviceconfig(service_config_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.serviceconfigmapping TO :username;

CREATE TABLE ambari.clusterservices (
  service_name VARCHAR(255) NOT NULL,
  cluster_id BIGINT NOT NULL,
  service_enabled INTEGER NOT NULL,
  CONSTRAINT PK_clusterservices PRIMARY KEY (service_name, cluster_id),
  CONSTRAINT FK_clusterservices_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.clusterservices TO :username;

CREATE TABLE ambari.clusterstate (
  cluster_id BIGINT NOT NULL,
  current_cluster_state VARCHAR(255) NOT NULL,
  current_stack_id BIGINT NOT NULL,
  CONSTRAINT PK_clusterstate PRIMARY KEY (cluster_id),
  CONSTRAINT FK_clusterstate_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id),
  CONSTRAINT FK_cs_current_stack_id FOREIGN KEY (current_stack_id) REFERENCES ambari.stack(stack_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.clusterstate TO :username;

CREATE TABLE ambari.repo_version (
  repo_version_id BIGINT NOT NULL,
  stack_id BIGINT NOT NULL,
  version VARCHAR(255) NOT NULL,
  display_name VARCHAR(128) NOT NULL,
  repositories TEXT NOT NULL,
  repo_type VARCHAR(255) DEFAULT 'STANDARD' NOT NULL,
  version_url VARCHAR(1024),
  version_xml TEXT,
  version_xsd VARCHAR(512),
  parent_id BIGINT,
  CONSTRAINT PK_repo_version PRIMARY KEY (repo_version_id),
  CONSTRAINT FK_repoversion_stack_id FOREIGN KEY (stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT UQ_repo_version_display_name UNIQUE (display_name),
  CONSTRAINT UQ_repo_version_stack_id UNIQUE (stack_id, version)
);
GRANT ALL PRIVILEGES ON TABLE ambari.repo_version TO :username;

CREATE TABLE ambari.cluster_version (
  id BIGINT NOT NULL,
  repo_version_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  state VARCHAR(32) NOT NULL,
  start_time BIGINT NOT NULL,
  end_time BIGINT,
  user_name VARCHAR(32),
  CONSTRAINT PK_cluster_version PRIMARY KEY (id),
  CONSTRAINT FK_cluster_version_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id),
  CONSTRAINT FK_cluster_version_repovers_id FOREIGN KEY (repo_version_id) REFERENCES ambari.repo_version (repo_version_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.cluster_version TO :username;

CREATE TABLE ambari.servicecomponentdesiredstate (
  id BIGINT NOT NULL,
  component_name VARCHAR(255) NOT NULL,
  cluster_id BIGINT NOT NULL,
  desired_stack_id BIGINT NOT NULL,
  desired_version VARCHAR(255) NOT NULL DEFAULT 'UNKNOWN',
  desired_state VARCHAR(255) NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  recovery_enabled SMALLINT NOT NULL DEFAULT 0,
  CONSTRAINT pk_sc_desiredstate PRIMARY KEY (id),
  CONSTRAINT UQ_scdesiredstate_name UNIQUE(component_name, service_name, cluster_id),
  CONSTRAINT FK_scds_desired_stack_id FOREIGN KEY (desired_stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT srvccmponentdesiredstatesrvcnm FOREIGN KEY (service_name, cluster_id) REFERENCES ambari.clusterservices (service_name, cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.servicecomponentdesiredstate TO :username;

CREATE TABLE ambari.hostcomponentdesiredstate (
  cluster_id BIGINT NOT NULL,
  component_name VARCHAR(255) NOT NULL,
  desired_stack_id BIGINT NOT NULL,
  desired_state VARCHAR(255) NOT NULL,
  host_id BIGINT NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  admin_state VARCHAR(32),
  maintenance_state VARCHAR(32) NOT NULL,
  security_state VARCHAR(32) NOT NULL DEFAULT 'UNSECURED',
  restart_required SMALLINT NOT NULL DEFAULT 0,
  CONSTRAINT PK_hostcomponentdesiredstate PRIMARY KEY (cluster_id, component_name, host_id, service_name),
  CONSTRAINT FK_hcdesiredstate_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id),
  CONSTRAINT FK_hcds_desired_stack_id FOREIGN KEY (desired_stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT hstcmpnntdesiredstatecmpnntnme FOREIGN KEY (component_name, service_name, cluster_id) REFERENCES ambari.servicecomponentdesiredstate (component_name, service_name, cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.hostcomponentdesiredstate TO :username;

CREATE TABLE ambari.hostcomponentstate (
  id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  component_name VARCHAR(255) NOT NULL,
  version VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
  current_stack_id BIGINT NOT NULL,
  current_state VARCHAR(255) NOT NULL,
  host_id BIGINT NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  upgrade_state VARCHAR(32) NOT NULL DEFAULT 'NONE',
  security_state VARCHAR(32) NOT NULL DEFAULT 'UNSECURED',
  CONSTRAINT pk_hostcomponentstate PRIMARY KEY (id),
  CONSTRAINT FK_hcs_current_stack_id FOREIGN KEY (current_stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT FK_hostcomponentstate_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id),
  CONSTRAINT hstcomponentstatecomponentname FOREIGN KEY (component_name, service_name, cluster_id) REFERENCES ambari.servicecomponentdesiredstate (component_name, service_name, cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.hostcomponentstate TO :username;
CREATE INDEX idx_host_component_state on ambari.hostcomponentstate(host_id, component_name, service_name, cluster_id);

CREATE TABLE ambari.hoststate (
  agent_version VARCHAR(255) NOT NULL,
  available_mem BIGINT NOT NULL,
  current_state VARCHAR(255) NOT NULL,
  health_status VARCHAR(255),
  host_id BIGINT NOT NULL,
  time_in_state BIGINT NOT NULL,
  maintenance_state VARCHAR(512),
  CONSTRAINT PK_hoststate PRIMARY KEY (host_id),
  CONSTRAINT FK_hoststate_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.hoststate TO :username;

CREATE TABLE ambari.host_version (
  id BIGINT NOT NULL,
  repo_version_id BIGINT NOT NULL,
  host_id BIGINT NOT NULL,
  state VARCHAR(32) NOT NULL,
  CONSTRAINT PK_host_version PRIMARY KEY (id),
  CONSTRAINT FK_host_version_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id),
  CONSTRAINT FK_host_version_repovers_id FOREIGN KEY (repo_version_id) REFERENCES ambari.repo_version (repo_version_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.host_version TO :username;

CREATE TABLE ambari.servicedesiredstate (
  cluster_id BIGINT NOT NULL,
  desired_host_role_mapping INTEGER NOT NULL,
  desired_stack_id BIGINT NOT NULL,
  desired_state VARCHAR(255) NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  maintenance_state VARCHAR(32) NOT NULL,
  security_state VARCHAR(32) NOT NULL DEFAULT 'UNSECURED',
  CONSTRAINT PK_servicedesiredstate PRIMARY KEY (cluster_id, service_name),
  CONSTRAINT FK_sds_desired_stack_id FOREIGN KEY (desired_stack_id) REFERENCES ambari.stack(stack_id),
  CONSTRAINT servicedesiredstateservicename FOREIGN KEY (service_name, cluster_id) REFERENCES ambari.clusterservices (service_name, cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.servicedesiredstate TO :username;

CREATE TABLE ambari.adminprincipaltype (
  principal_type_id INTEGER NOT NULL,
  principal_type_name VARCHAR(255) NOT NULL,
  CONSTRAINT PK_adminprincipaltype PRIMARY KEY (principal_type_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.adminprincipaltype TO :username;

CREATE TABLE ambari.adminprincipal (
  principal_id BIGINT NOT NULL,
  principal_type_id INTEGER NOT NULL,
  CONSTRAINT PK_adminprincipal PRIMARY KEY (principal_id),
  CONSTRAINT FK_principal_principal_type_id FOREIGN KEY (principal_type_id) REFERENCES ambari.adminprincipaltype(principal_type_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.adminprincipal TO :username;

CREATE TABLE ambari.users (
  user_id INTEGER,
  principal_id BIGINT NOT NULL,
  ldap_user INTEGER NOT NULL DEFAULT 0,
  user_name VARCHAR(255) NOT NULL,
  user_type VARCHAR(255) NOT NULL DEFAULT 'LOCAL',
  create_time TIMESTAMP DEFAULT NOW(),
  user_password VARCHAR(255),
  active INTEGER NOT NULL DEFAULT 1,
  active_widget_layouts VARCHAR(1024) DEFAULT NULL,
  CONSTRAINT PK_users PRIMARY KEY (user_id),
  CONSTRAINT FK_users_principal_id FOREIGN KEY (principal_id) REFERENCES ambari.adminprincipal(principal_id),
  CONSTRAINT UNQ_users_0 UNIQUE (user_name, user_type)
);
GRANT ALL PRIVILEGES ON TABLE ambari.users TO :username;

CREATE TABLE ambari.groups (
  group_id INTEGER,
  principal_id BIGINT NOT NULL,
  group_name VARCHAR(255) NOT NULL,
  ldap_group INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT PK_groups PRIMARY KEY (group_id),
  UNIQUE (ldap_group, group_name),
  CONSTRAINT FK_groups_principal_id FOREIGN KEY (principal_id) REFERENCES ambari.adminprincipal(principal_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.groups TO :username;

CREATE TABLE ambari.members (
  member_id INTEGER,
  group_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  CONSTRAINT PK_members PRIMARY KEY (member_id),
  UNIQUE(group_id, user_id),
  CONSTRAINT FK_members_group_id FOREIGN KEY (group_id) REFERENCES ambari.groups (group_id),
  CONSTRAINT FK_members_user_id FOREIGN KEY (user_id) REFERENCES ambari.users (user_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.members TO :username;

CREATE TABLE ambari.requestschedule (
  schedule_id bigint,
  cluster_id bigint NOT NULL,
  description varchar(255),
  status varchar(255),
  batch_separation_seconds smallint,
  batch_toleration_limit smallint,
  authenticated_user_id INTEGER,
  create_user varchar(255),
  create_timestamp bigint,
  update_user varchar(255),
  update_timestamp bigint,
  minutes varchar(10),
  hours varchar(10),
  days_of_month varchar(10),
  month varchar(10),
  day_of_week varchar(10),
  yearToSchedule varchar(10),
  startTime varchar(50),
  endTime varchar(50),
  last_execution_status varchar(255),
  CONSTRAINT PK_requestschedule PRIMARY KEY (schedule_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.requestschedule TO :username;

CREATE TABLE ambari.request (
  request_id BIGINT NOT NULL,
  cluster_id BIGINT,
  command_name VARCHAR(255),
  create_time BIGINT NOT NULL,
  end_time BIGINT NOT NULL,
  exclusive_execution SMALLINT NOT NULL DEFAULT 0,
  inputs BYTEA,
  request_context VARCHAR(255),
  request_type VARCHAR(255),
  request_schedule_id BIGINT,
  start_time BIGINT NOT NULL,
  status VARCHAR(255),
  CONSTRAINT PK_request PRIMARY KEY (request_id),
  CONSTRAINT FK_request_schedule_id FOREIGN KEY (request_schedule_id) REFERENCES ambari.requestschedule (schedule_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.request TO :username;

CREATE TABLE ambari.stage (
  stage_id BIGINT NOT NULL,
  request_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  skippable SMALLINT DEFAULT 0 NOT NULL,
  supports_auto_skip_failure SMALLINT DEFAULT 0 NOT NULL,
  log_info VARCHAR(255) NOT NULL,
  request_context VARCHAR(255),
  cluster_host_info BYTEA NOT NULL,
  command_params BYTEA,
  host_params BYTEA,
  CONSTRAINT PK_stage PRIMARY KEY (stage_id, request_id),
  CONSTRAINT FK_stage_request_id FOREIGN KEY (request_id) REFERENCES ambari.request (request_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.stage TO :username;

CREATE TABLE ambari.host_role_command (
  task_id BIGINT NOT NULL,
  attempt_count SMALLINT NOT NULL,
  retry_allowed SMALLINT DEFAULT 0 NOT NULL,
  event VARCHAR(32000) NOT NULL,
  exitcode INTEGER NOT NULL,
  host_id BIGINT,
  last_attempt_time BIGINT NOT NULL,
  request_id BIGINT NOT NULL,
  role VARCHAR(255),
  stage_id BIGINT NOT NULL,
  start_time BIGINT NOT NULL,
  original_start_time BIGINT NOT NULL,
  end_time BIGINT,
  status VARCHAR(255),
  auto_skip_on_failure SMALLINT DEFAULT 0 NOT NULL,
  std_error BYTEA,
  std_out BYTEA,
  output_log VARCHAR(255) NULL,
  error_log VARCHAR(255) NULL,
  structured_out BYTEA,
  role_command VARCHAR(255),
  command_detail VARCHAR(255),
  custom_command_name VARCHAR(255),
  CONSTRAINT PK_host_role_command PRIMARY KEY (task_id),
  CONSTRAINT FK_host_role_command_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id),
  CONSTRAINT FK_host_role_command_stage_id FOREIGN KEY (stage_id, request_id) REFERENCES ambari.stage (stage_id, request_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.host_role_command TO :username;

CREATE TABLE ambari.execution_command (
  command BYTEA,
  task_id BIGINT NOT NULL,
  CONSTRAINT PK_execution_command PRIMARY KEY (task_id),
  CONSTRAINT FK_execution_command_task_id FOREIGN KEY (task_id) REFERENCES ambari.host_role_command (task_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.execution_command TO :username;

CREATE TABLE ambari.role_success_criteria (
  role VARCHAR(255) NOT NULL,
  request_id BIGINT NOT NULL,
  stage_id BIGINT NOT NULL,
  success_factor FLOAT NOT NULL,
  CONSTRAINT PK_role_success_criteria PRIMARY KEY (role, request_id, stage_id),
  CONSTRAINT role_success_criteria_stage_id FOREIGN KEY (stage_id, request_id) REFERENCES ambari.stage (stage_id, request_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.role_success_criteria TO :username;

CREATE TABLE ambari.requestresourcefilter (
  filter_id BIGINT NOT NULL,
  request_id BIGINT NOT NULL,
  service_name VARCHAR(255),
  component_name VARCHAR(255),
  hosts BYTEA,
  CONSTRAINT PK_requestresourcefilter PRIMARY KEY (filter_id),
  CONSTRAINT FK_reqresfilter_req_id FOREIGN KEY (request_id) REFERENCES ambari.request (request_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.requestresourcefilter TO :username;

CREATE TABLE ambari.requestoperationlevel (
  operation_level_id BIGINT NOT NULL,
  request_id BIGINT NOT NULL,
  level_name VARCHAR(255),
  cluster_name VARCHAR(255),
  service_name VARCHAR(255),
  host_component_name VARCHAR(255),
  host_id BIGINT NULL,      -- unlike most host_id columns, this one allows NULLs because the request can be at the service level
  CONSTRAINT PK_requestoperationlevel PRIMARY KEY (operation_level_id),
  CONSTRAINT FK_req_op_level_req_id FOREIGN KEY (request_id) REFERENCES ambari.request (request_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.requestoperationlevel TO :username;

CREATE TABLE ambari.ClusterHostMapping (
  cluster_id BIGINT NOT NULL,
  host_id BIGINT NOT NULL,
  CONSTRAINT PK_ClusterHostMapping PRIMARY KEY (cluster_id, host_id),
  CONSTRAINT FK_clhostmapping_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id),
  CONSTRAINT FK_clusterhostmapping_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.ClusterHostMapping TO :username;

CREATE TABLE ambari.key_value_store (
  "key" VARCHAR(255),
  "value" VARCHAR,
  CONSTRAINT PK_key_value_store PRIMARY KEY ("key")
);
GRANT ALL PRIVILEGES ON TABLE ambari.key_value_store TO :username;

CREATE TABLE ambari.hostconfigmapping (
  cluster_id BIGINT NOT NULL,
  host_id BIGINT NOT NULL,
  type_name VARCHAR(255) NOT NULL,
  version_tag VARCHAR(255) NOT NULL,
  service_name VARCHAR(255),
  create_timestamp BIGINT NOT NULL,
  selected INTEGER NOT NULL DEFAULT 0,
  user_name VARCHAR(255) NOT NULL DEFAULT '_db',
  CONSTRAINT PK_hostconfigmapping PRIMARY KEY (cluster_id, host_id, type_name, create_timestamp),
  CONSTRAINT FK_hostconfmapping_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id),
  CONSTRAINT FK_hostconfmapping_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.hostconfigmapping TO :username;

CREATE TABLE ambari.metainfo (
  "metainfo_key" VARCHAR(255),
  "metainfo_value" VARCHAR,
  CONSTRAINT PK_metainfo PRIMARY KEY ("metainfo_key")
);
GRANT ALL PRIVILEGES ON TABLE ambari.metainfo TO :username;

CREATE TABLE ambari.ambari_sequences (
  sequence_name VARCHAR(255),
  sequence_value BIGINT NOT NULL,
  CONSTRAINT pk_ambari_sequences PRIMARY KEY (sequence_name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.ambari_sequences TO :username;

CREATE TABLE ambari.configgroup (
  group_id BIGINT,
  cluster_id BIGINT NOT NULL,
  group_name VARCHAR(255) NOT NULL,
  tag VARCHAR(1024) NOT NULL,
  description VARCHAR(1024),
  create_timestamp BIGINT NOT NULL,
  service_name VARCHAR(255),
  CONSTRAINT PK_configgroup PRIMARY KEY (group_id),
  CONSTRAINT FK_configgroup_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters (cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.configgroup TO :username;

CREATE TABLE ambari.confgroupclusterconfigmapping (
  config_group_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  config_type VARCHAR(255) NOT NULL,
  version_tag VARCHAR(255) NOT NULL,
  user_name VARCHAR(255) DEFAULT '_db',
  create_timestamp BIGINT NOT NULL,
  CONSTRAINT PK_confgroupclustercfgmapping PRIMARY KEY (config_group_id, cluster_id, config_type),
  CONSTRAINT FK_cgccm_gid FOREIGN KEY (config_group_id) REFERENCES ambari.configgroup (group_id),
  CONSTRAINT FK_confg FOREIGN KEY (version_tag, config_type, cluster_id) REFERENCES ambari.clusterconfig (version_tag, type_name, cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.confgroupclusterconfigmapping TO :username;

CREATE TABLE ambari.configgrouphostmapping (
  config_group_id BIGINT NOT NULL,
  host_id BIGINT NOT NULL,
  CONSTRAINT PK_configgrouphostmapping PRIMARY KEY (config_group_id, host_id),
  CONSTRAINT FK_cghm_cgid FOREIGN KEY (config_group_id) REFERENCES ambari.configgroup (group_id),
  CONSTRAINT FK_cghm_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.configgrouphostmapping TO :username;

CREATE TABLE ambari.requestschedulebatchrequest (
  schedule_id bigint,
  batch_id bigint,
  request_id bigint,
  request_type varchar(255),
  request_uri varchar(1024),
  request_body BYTEA,
  request_status varchar(255),
  return_code smallint,
  return_message varchar(20000),
  CONSTRAINT PK_requestschedulebatchrequest PRIMARY KEY (schedule_id, batch_id),
  CONSTRAINT FK_rsbatchrequest_schedule_id FOREIGN KEY (schedule_id) REFERENCES ambari.requestschedule (schedule_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.requestschedulebatchrequest TO :username;

CREATE TABLE ambari.blueprint (
  blueprint_name VARCHAR(255) NOT NULL,
  stack_id BIGINT NOT NULL,
  security_type VARCHAR(32) NOT NULL DEFAULT 'NONE',
  security_descriptor_reference VARCHAR(255),
  CONSTRAINT PK_blueprint PRIMARY KEY (blueprint_name),
  CONSTRAINT FK_blueprint_stack_id FOREIGN KEY (stack_id) REFERENCES ambari.stack(stack_id));

CREATE TABLE ambari.hostgroup (
  blueprint_name VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  cardinality VARCHAR(255) NOT NULL,
  CONSTRAINT PK_hostgroup PRIMARY KEY (blueprint_name, name),
  CONSTRAINT FK_hg_blueprint_name FOREIGN KEY (blueprint_name) REFERENCES ambari.blueprint(blueprint_name));

CREATE TABLE ambari.hostgroup_component (
  blueprint_name VARCHAR(255) NOT NULL,
  hostgroup_name VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  provision_action VARCHAR(255),
  CONSTRAINT PK_hostgroup_component PRIMARY KEY (blueprint_name, hostgroup_name, name),
  CONSTRAINT FK_hgc_blueprint_name FOREIGN KEY (blueprint_name, hostgroup_name) REFERENCES ambari.hostgroup (blueprint_name, name));

CREATE TABLE ambari.blueprint_configuration (
  blueprint_name varchar(255) NOT NULL,
  type_name varchar(255) NOT NULL,
  config_data TEXT NOT NULL,
  config_attributes TEXT,
  CONSTRAINT PK_blueprint_configuration PRIMARY KEY (blueprint_name, type_name),
  CONSTRAINT FK_cfg_blueprint_name FOREIGN KEY (blueprint_name) REFERENCES ambari.blueprint(blueprint_name));

CREATE TABLE ambari.blueprint_setting (
  id BIGINT NOT NULL,
  blueprint_name varchar(255) NOT NULL,
  setting_name varchar(255) NOT NULL,
  setting_data TEXT NOT NULL,
  CONSTRAINT PK_blueprint_setting PRIMARY KEY (id),
  CONSTRAINT UQ_blueprint_setting_name UNIQUE(blueprint_name,setting_name),
  CONSTRAINT FK_blueprint_setting_name FOREIGN KEY (blueprint_name) REFERENCES ambari.blueprint(blueprint_name));

CREATE TABLE ambari.hostgroup_configuration (
  blueprint_name VARCHAR(255) NOT NULL,
  hostgroup_name VARCHAR(255) NOT NULL,
  type_name VARCHAR(255) NOT NULL,
  config_data TEXT NOT NULL,
  config_attributes TEXT,
  CONSTRAINT PK_hostgroup_configuration PRIMARY KEY (blueprint_name, hostgroup_name, type_name),
  CONSTRAINT FK_hg_cfg_bp_hg_name FOREIGN KEY (blueprint_name, hostgroup_name) REFERENCES ambari.hostgroup (blueprint_name, name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.blueprint TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.hostgroup TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.hostgroup_component TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.blueprint_configuration TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.blueprint_setting TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.hostgroup_configuration TO :username;

CREATE TABLE ambari.viewmain (
  view_name VARCHAR(255) NOT NULL,
  label VARCHAR(255),
  description VARCHAR(2048),
  version VARCHAR(255),
  build VARCHAR(128),
  resource_type_id INTEGER NOT NULL,
  icon VARCHAR(255),
  icon64 VARCHAR(255),
  archive VARCHAR(255),
  mask VARCHAR(255),
  system_view SMALLINT NOT NULL DEFAULT 0,
  CONSTRAINT PK_viewmain PRIMARY KEY (view_name),
  CONSTRAINT FK_view_resource_type_id FOREIGN KEY (resource_type_id) REFERENCES ambari.adminresourcetype(resource_type_id));



CREATE table ambari.viewurl(
  url_id BIGINT ,
  url_name VARCHAR(255) NOT NULL ,
  url_suffix VARCHAR(255) NOT NULL,
  PRIMARY KEY(url_id)
);


CREATE TABLE ambari.viewinstance (
  view_instance_id BIGINT,
  resource_id BIGINT NOT NULL,
  view_name VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  label VARCHAR(255),
  description VARCHAR(2048),
  visible CHAR(1),
  icon VARCHAR(255),
  icon64 VARCHAR(255),
  xml_driven CHAR(1),
  alter_names SMALLINT NOT NULL DEFAULT 1,
  cluster_handle BIGINT,
  cluster_type VARCHAR(100) NOT NULL DEFAULT 'LOCAL_AMBARI',
  short_url BIGINT,
  CONSTRAINT PK_viewinstance PRIMARY KEY (view_instance_id),
  CONSTRAINT FK_instance_url_id FOREIGN KEY (short_url) REFERENCES ambari.viewurl(url_id),
  CONSTRAINT FK_viewinst_view_name FOREIGN KEY (view_name) REFERENCES ambari.viewmain(view_name),
  CONSTRAINT FK_viewinstance_resource_id FOREIGN KEY (resource_id) REFERENCES ambari.adminresource(resource_id),
  CONSTRAINT UQ_viewinstance_name UNIQUE (view_name, name),
  CONSTRAINT UQ_viewinstance_name_id UNIQUE (view_instance_id, view_name, name));

CREATE TABLE ambari.viewinstancedata (
  view_instance_id BIGINT,
  view_name VARCHAR(255) NOT NULL,
  view_instance_name VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  user_name VARCHAR(255) NOT NULL,
  value VARCHAR(2000),
  CONSTRAINT PK_viewinstancedata PRIMARY KEY (view_instance_id, name, user_name),
  CONSTRAINT FK_viewinstdata_view_name FOREIGN KEY (view_instance_id, view_name, view_instance_name) REFERENCES ambari.viewinstance(view_instance_id, view_name, name));

CREATE TABLE ambari.viewinstanceproperty (
  view_name VARCHAR(255) NOT NULL,
  view_instance_name VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  value VARCHAR(2000),
  CONSTRAINT PK_viewinstanceproperty PRIMARY KEY (view_name, view_instance_name, name),
  CONSTRAINT FK_viewinstprop_view_name FOREIGN KEY (view_name, view_instance_name) REFERENCES ambari.viewinstance(view_name, name));

CREATE TABLE ambari.viewparameter (
  view_name VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(2048),
  label VARCHAR(255),
  placeholder VARCHAR(255),
  default_value VARCHAR(2000),
  cluster_config VARCHAR(255),
  required CHAR(1),
  masked CHAR(1),
  CONSTRAINT PK_viewparameter PRIMARY KEY (view_name, name),
  CONSTRAINT FK_viewparam_view_name FOREIGN KEY (view_name) REFERENCES ambari.viewmain(view_name));

CREATE TABLE ambari.viewresource (
  view_name VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  plural_name VARCHAR(255),
  id_property VARCHAR(255),
  subResource_names VARCHAR(255),
  provider VARCHAR(255),
  service VARCHAR(255),
  resource VARCHAR(255),
  CONSTRAINT PK_viewresource PRIMARY KEY (view_name, name),
  CONSTRAINT FK_viewres_view_name FOREIGN KEY (view_name) REFERENCES ambari.viewmain(view_name));

CREATE TABLE ambari.viewentity (
  id BIGINT NOT NULL,
  view_name VARCHAR(255) NOT NULL,
  view_instance_name VARCHAR(255) NOT NULL,
  class_name VARCHAR(255) NOT NULL,
  id_property VARCHAR(255),
  CONSTRAINT PK_viewentity PRIMARY KEY (id),
  CONSTRAINT FK_viewentity_view_name FOREIGN KEY (view_name, view_instance_name) REFERENCES ambari.viewinstance(view_name, name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.viewmain TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.viewinstancedata TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.viewurl TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.viewinstance TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.viewinstanceproperty TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.viewparameter TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.viewresource TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.viewentity TO :username;

CREATE TABLE ambari.adminpermission (
  permission_id BIGINT NOT NULL,
  permission_name VARCHAR(255) NOT NULL,
  resource_type_id INTEGER NOT NULL,
  permission_label VARCHAR(255),
  principal_id BIGINT NOT NULL,
  sort_order SMALLINT NOT NULL DEFAULT 1,
  CONSTRAINT PK_adminpermission PRIMARY KEY (permission_id),
  CONSTRAINT FK_permission_resource_type_id FOREIGN KEY (resource_type_id) REFERENCES ambari.adminresourcetype(resource_type_id),
  CONSTRAINT FK_permission_principal_id FOREIGN KEY (principal_id) REFERENCES ambari.adminprincipal(principal_id),
  CONSTRAINT UQ_perm_name_resource_type_id UNIQUE (permission_name, resource_type_id));

CREATE TABLE ambari.roleauthorization (
  authorization_id VARCHAR(100) NOT NULL,
  authorization_name VARCHAR(255) NOT NULL,
  CONSTRAINT PK_roleauthorization PRIMARY KEY (authorization_id));

CREATE TABLE ambari.permission_roleauthorization (
  permission_id BIGINT NOT NULL,
  authorization_id VARCHAR(100) NOT NULL,
  CONSTRAINT PK_permsn_roleauthorization PRIMARY KEY (permission_id, authorization_id),
  CONSTRAINT FK_permission_roleauth_aid FOREIGN KEY (authorization_id) REFERENCES ambari.roleauthorization(authorization_id),
  CONSTRAINT FK_permission_roleauth_pid FOREIGN KEY (permission_id) REFERENCES ambari.adminpermission(permission_id));

CREATE TABLE ambari.adminprivilege (
  privilege_id BIGINT,
  permission_id BIGINT NOT NULL,
  resource_id BIGINT NOT NULL,
  principal_id BIGINT NOT NULL,
  CONSTRAINT PK_adminprivilege PRIMARY KEY (privilege_id),
  CONSTRAINT FK_privilege_permission_id FOREIGN KEY (permission_id) REFERENCES ambari.adminpermission(permission_id),
  CONSTRAINT FK_privilege_principal_id FOREIGN KEY (principal_id) REFERENCES ambari.adminprincipal(principal_id),
  CONSTRAINT FK_privilege_resource_id FOREIGN KEY (resource_id) REFERENCES ambari.adminresource(resource_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.adminpermission TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.roleauthorization TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.permission_roleauthorization TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.adminprivilege TO :username;

CREATE TABLE ambari.artifact (
  artifact_name VARCHAR(255) NOT NULL,
  artifact_data TEXT NOT NULL,
  foreign_keys VARCHAR(255) NOT NULL,
  CONSTRAINT PK_artifact PRIMARY KEY (artifact_name, foreign_keys)
);
GRANT ALL PRIVILEGES ON TABLE ambari.artifact TO :username;

CREATE TABLE ambari.widget (
  id BIGINT NOT NULL,
  widget_name VARCHAR(255) NOT NULL,
  widget_type VARCHAR(255) NOT NULL,
  metrics TEXT,
  time_created BIGINT NOT NULL,
  author VARCHAR(255),
  description VARCHAR(2048),
  default_section_name VARCHAR(255),
  scope VARCHAR(255),
  widget_values TEXT,
  properties TEXT,
  cluster_id BIGINT NOT NULL,
  CONSTRAINT PK_widget PRIMARY KEY (id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.widget TO :username;

CREATE TABLE ambari.widget_layout (
  id BIGINT NOT NULL,
  layout_name VARCHAR(255) NOT NULL,
  section_name VARCHAR(255) NOT NULL,
  scope VARCHAR(255) NOT NULL,
  user_name VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  cluster_id BIGINT NOT NULL,
  CONSTRAINT PK_widget_layout PRIMARY KEY (id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.widget_layout TO :username;

CREATE TABLE ambari.widget_layout_user_widget (
  widget_layout_id BIGINT NOT NULL,
  widget_id BIGINT NOT NULL,
  widget_order smallint,
  CONSTRAINT PK_widget_layout_user_widget PRIMARY KEY (widget_layout_id, widget_id),
  CONSTRAINT FK_widget_id FOREIGN KEY (widget_id) REFERENCES ambari.widget(id),
  CONSTRAINT FK_widget_layout_id FOREIGN KEY (widget_layout_id) REFERENCES ambari.widget_layout(id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.widget_layout_user_widget TO :username;

CREATE TABLE ambari.topology_request (
  id BIGINT NOT NULL,
  action VARCHAR(255) NOT NULL,
  cluster_id BIGINT NOT NULL,
  bp_name VARCHAR(100) NOT NULL,
  cluster_properties TEXT,
  cluster_attributes TEXT,
  description VARCHAR(1024),
  provision_action VARCHAR(255),
  CONSTRAINT PK_topology_request PRIMARY KEY (id),
  CONSTRAINT FK_topology_request_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.clusters(cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.topology_request TO :username;

CREATE TABLE ambari.topology_hostgroup (
  id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  group_properties TEXT,
  group_attributes TEXT,
  request_id BIGINT NOT NULL,
  CONSTRAINT PK_topology_hostgroup PRIMARY KEY (id),
  CONSTRAINT FK_hostgroup_req_id FOREIGN KEY (request_id) REFERENCES ambari.topology_request(id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.topology_hostgroup TO :username;

CREATE TABLE ambari.topology_host_info (
  id BIGINT NOT NULL,
  group_id BIGINT NOT NULL,
  fqdn VARCHAR(255),
  host_id BIGINT,
  host_count INTEGER,
  predicate VARCHAR(2048),
  rack_info VARCHAR(255),
  CONSTRAINT PK_topology_host_info PRIMARY KEY (id),
  CONSTRAINT FK_hostinfo_group_id FOREIGN KEY (group_id) REFERENCES ambari.topology_hostgroup(id),
  CONSTRAINT FK_hostinfo_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts(host_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.topology_host_info TO :username;

CREATE TABLE ambari.topology_logical_request (
  id BIGINT NOT NULL,
  request_id BIGINT NOT NULL,
  description VARCHAR(1024),
  CONSTRAINT PK_topology_logical_request PRIMARY KEY (id),
  CONSTRAINT FK_logicalreq_req_id FOREIGN KEY (request_id) REFERENCES ambari.topology_request(id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.topology_logical_request TO :username;

CREATE TABLE ambari.topology_host_request (
  id BIGINT NOT NULL,
  logical_request_id BIGINT NOT NULL,
  group_id BIGINT NOT NULL,
  stage_id BIGINT NOT NULL,
  host_name VARCHAR(255),
  CONSTRAINT PK_topology_host_request PRIMARY KEY (id),
  CONSTRAINT FK_hostreq_group_id FOREIGN KEY (group_id) REFERENCES ambari.topology_hostgroup(id),
  CONSTRAINT FK_hostreq_logicalreq_id FOREIGN KEY (logical_request_id) REFERENCES ambari.topology_logical_request(id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.topology_host_request TO :username;

CREATE TABLE ambari.topology_host_task (
  id BIGINT NOT NULL,
  host_request_id BIGINT NOT NULL,
  type VARCHAR(255) NOT NULL,
  CONSTRAINT PK_topology_host_task PRIMARY KEY (id),
  CONSTRAINT FK_hosttask_req_id FOREIGN KEY (host_request_id) REFERENCES ambari.topology_host_request (id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.topology_host_task TO :username;

CREATE TABLE ambari.topology_logical_task (
  id BIGINT NOT NULL,
  host_task_id BIGINT NOT NULL,
  physical_task_id BIGINT,
  component VARCHAR(255) NOT NULL,
  CONSTRAINT PK_topology_logical_task PRIMARY KEY (id),
  CONSTRAINT FK_ltask_hosttask_id FOREIGN KEY (host_task_id) REFERENCES ambari.topology_host_task (id),
  CONSTRAINT FK_ltask_hrc_id FOREIGN KEY (physical_task_id) REFERENCES ambari.host_role_command (task_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.topology_logical_task TO :username;

CREATE TABLE ambari.setting (
  id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL UNIQUE,
  setting_type VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  updated_by VARCHAR(255) NOT NULL DEFAULT '_db',
  update_timestamp BIGINT NOT NULL,
  CONSTRAINT PK_setting PRIMARY KEY (id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.setting TO :username;

-- Remote Cluster table

CREATE TABLE ambari.remoteambaricluster(
  cluster_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  username VARCHAR(255) NOT NULL,
  url VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  CONSTRAINT PK_remote_ambari_cluster PRIMARY KEY (cluster_id),
  CONSTRAINT UQ_remote_ambari_cluster UNIQUE (name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.remoteambaricluster TO :username;

CREATE TABLE ambari.remoteambariclusterservice(
  id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  CONSTRAINT PK_remote_ambari_service PRIMARY KEY (id),
  CONSTRAINT FK_remote_ambari_cluster_id FOREIGN KEY (cluster_id) REFERENCES ambari.remoteambaricluster(cluster_id)
);
GRANT ALL PRIVILEGES ON TABLE ambari.remoteambariclusterservice TO :username;

-- Remote Cluster table ends

-- upgrade tables
CREATE TABLE ambari.upgrade (
  upgrade_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  request_id BIGINT NOT NULL,
  from_version VARCHAR(255) DEFAULT '' NOT NULL,
  to_version VARCHAR(255) DEFAULT '' NOT NULL,
  direction VARCHAR(255) DEFAULT 'UPGRADE' NOT NULL,
  upgrade_package VARCHAR(255) NOT NULL,
  upgrade_type VARCHAR(32) NOT NULL,
  skip_failures SMALLINT DEFAULT 0 NOT NULL,
  skip_sc_failures SMALLINT DEFAULT 0 NOT NULL,
  downgrade_allowed SMALLINT DEFAULT 1 NOT NULL,
  suspended SMALLINT DEFAULT 0 NOT NULL,
  CONSTRAINT PK_upgrade PRIMARY KEY (upgrade_id),
  FOREIGN KEY (cluster_id) REFERENCES ambari.clusters(cluster_id),
  FOREIGN KEY (request_id) REFERENCES ambari.request(request_id)
);

CREATE TABLE ambari.upgrade_group (
  upgrade_group_id BIGINT NOT NULL,
  upgrade_id BIGINT NOT NULL,
  group_name VARCHAR(255) DEFAULT '' NOT NULL,
  group_title VARCHAR(1024) DEFAULT '' NOT NULL,
  CONSTRAINT PK_upgrade_group PRIMARY KEY (upgrade_group_id),
  FOREIGN KEY (upgrade_id) REFERENCES ambari.upgrade(upgrade_id)
);

CREATE TABLE ambari.upgrade_item (
  upgrade_item_id BIGINT NOT NULL,
  upgrade_group_id BIGINT NOT NULL,
  stage_id BIGINT NOT NULL,
  state VARCHAR(255) DEFAULT 'NONE' NOT NULL,
  hosts TEXT,
  tasks TEXT,
  item_text VARCHAR(1024),
  CONSTRAINT PK_upgrade_item PRIMARY KEY (upgrade_item_id),
  FOREIGN KEY (upgrade_group_id) REFERENCES ambari.upgrade_group(upgrade_group_id)
);

CREATE TABLE ambari.servicecomponent_history(
  id BIGINT NOT NULL,
  component_id BIGINT NOT NULL,
  upgrade_id BIGINT NOT NULL,
  from_stack_id BIGINT NOT NULL,
  to_stack_id BIGINT NOT NULL,
  CONSTRAINT PK_sc_history PRIMARY KEY (id),
  CONSTRAINT FK_sc_history_component_id FOREIGN KEY (component_id) REFERENCES ambari.servicecomponentdesiredstate (id),
  CONSTRAINT FK_sc_history_upgrade_id FOREIGN KEY (upgrade_id) REFERENCES ambari.upgrade (upgrade_id),
  CONSTRAINT FK_sc_history_from_stack_id FOREIGN KEY (from_stack_id) REFERENCES ambari.stack (stack_id),
  CONSTRAINT FK_sc_history_to_stack_id FOREIGN KEY (to_stack_id) REFERENCES ambari.stack (stack_id)
);

CREATE TABLE ambari.ambari_operation_history(
  id BIGINT NOT NULL,
  from_version VARCHAR(255) NOT NULL,
  to_version VARCHAR(255) NOT NULL,
  start_time BIGINT NOT NULL,
  end_time BIGINT,
  operation_type VARCHAR(255) NOT NULL,
  comments TEXT,
  CONSTRAINT PK_ambari_operation_history PRIMARY KEY (id)
);

GRANT ALL PRIVILEGES ON TABLE ambari.upgrade TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.upgrade_group TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.upgrade_item TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.servicecomponent_history TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.ambari_operation_history TO :username;

-- tasks indices --
CREATE INDEX idx_stage_request_id ON ambari.stage (request_id);
CREATE INDEX idx_hrc_request_id ON ambari.host_role_command (request_id);
CREATE INDEX idx_hrc_status_role ON ambari.host_role_command (status, role);
CREATE INDEX idx_rsc_request_id ON ambari.role_success_criteria (request_id);

-------- altering tables by creating foreign keys ----------
-- #1: This should always be an exceptional case. FK constraints should be inlined in table definitions when possible
--     (reorder table definitions if necessary).
-- #2: Oracle has a limitation of 30 chars in the constraint names name, and we should use the same constraint names in all DB types.
ALTER TABLE ambari.clusters ADD CONSTRAINT FK_clusters_upgrade_id FOREIGN KEY (upgrade_id) REFERENCES ambari.upgrade (upgrade_id);

-- Kerberos
CREATE TABLE ambari.kerberos_principal (
  principal_name VARCHAR(255) NOT NULL,
  is_service SMALLINT NOT NULL DEFAULT 1,
  cached_keytab_path VARCHAR(255),
  CONSTRAINT PK_kerberos_principal PRIMARY KEY (principal_name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.kerberos_principal TO :username;

CREATE TABLE ambari.kerberos_principal_host (
  principal_name VARCHAR(255) NOT NULL,
  host_id BIGINT NOT NULL,
  CONSTRAINT PK_kerberos_principal_host PRIMARY KEY (principal_name, host_id),
  CONSTRAINT FK_krb_pr_host_id FOREIGN KEY (host_id) REFERENCES ambari.hosts (host_id),
  CONSTRAINT FK_krb_pr_host_principalname FOREIGN KEY (principal_name) REFERENCES ambari.kerberos_principal (principal_name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.kerberos_principal_host TO :username;

CREATE TABLE ambari.kerberos_descriptor
(
   kerberos_descriptor_name   VARCHAR(255) NOT NULL,
   kerberos_descriptor        TEXT NOT NULL,
   CONSTRAINT PK_kerberos_descriptor PRIMARY KEY (kerberos_descriptor_name)
);
GRANT ALL PRIVILEGES ON TABLE ambari.kerberos_descriptor TO :username;

-- Kerberos (end)

-- Alerting Framework
CREATE TABLE ambari.alert_definition (
  definition_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  definition_name VARCHAR(255) NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  component_name VARCHAR(255),
  scope VARCHAR(255) DEFAULT 'ANY' NOT NULL,
  label VARCHAR(255),
  help_url VARCHAR(512),
  description TEXT,
  enabled SMALLINT DEFAULT 1 NOT NULL,
  schedule_interval INTEGER NOT NULL,
  source_type VARCHAR(255) NOT NULL,
  alert_source TEXT NOT NULL,
  hash VARCHAR(64) NOT NULL,
  ignore_host SMALLINT DEFAULT 0 NOT NULL,
  repeat_tolerance INTEGER DEFAULT 1 NOT NULL,
  repeat_tolerance_enabled SMALLINT DEFAULT 0 NOT NULL,
  CONSTRAINT PK_alert_definition PRIMARY KEY (definition_id),
  FOREIGN KEY (cluster_id) REFERENCES ambari.clusters(cluster_id),
  CONSTRAINT uni_alert_def_name UNIQUE(cluster_id,definition_name)
);

CREATE TABLE ambari.alert_history (
  alert_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  alert_definition_id BIGINT NOT NULL,
  service_name VARCHAR(255) NOT NULL,
  component_name VARCHAR(255),
  host_name VARCHAR(255),
  alert_instance VARCHAR(255),
  alert_timestamp BIGINT NOT NULL,
  alert_label VARCHAR(1024),
  alert_state VARCHAR(255) NOT NULL,
  alert_text TEXT,
  CONSTRAINT PK_alert_history PRIMARY KEY (alert_id),
  FOREIGN KEY (alert_definition_id) REFERENCES ambari.alert_definition(definition_id),
  FOREIGN KEY (cluster_id) REFERENCES ambari.clusters(cluster_id)
);

CREATE TABLE ambari.alert_current (
  alert_id BIGINT NOT NULL,
  definition_id BIGINT NOT NULL,
  history_id BIGINT NOT NULL UNIQUE,
  maintenance_state VARCHAR(255) NOT NULL,
  original_timestamp BIGINT NOT NULL,
  latest_timestamp BIGINT NOT NULL,
  latest_text TEXT,
  occurrences BIGINT NOT NULL DEFAULT 1,
  firmness VARCHAR(255) NOT NULL DEFAULT 'HARD',
  CONSTRAINT PK_alert_current PRIMARY KEY (alert_id),
  FOREIGN KEY (definition_id) REFERENCES ambari.alert_definition(definition_id),
  FOREIGN KEY (history_id) REFERENCES ambari.alert_history(alert_id)
);

CREATE TABLE ambari.alert_group (
  group_id BIGINT NOT NULL,
  cluster_id BIGINT NOT NULL,
  group_name VARCHAR(255) NOT NULL,
  is_default SMALLINT NOT NULL DEFAULT 0,
  service_name VARCHAR(255),
  CONSTRAINT PK_alert_group PRIMARY KEY (group_id),
  CONSTRAINT uni_alert_group_name UNIQUE(cluster_id,group_name)
);

CREATE TABLE ambari.alert_target (
  target_id BIGINT NOT NULL,
  target_name VARCHAR(255) NOT NULL UNIQUE,
  notification_type VARCHAR(64) NOT NULL,
  properties TEXT,
  description VARCHAR(1024),
  is_global SMALLINT NOT NULL DEFAULT 0,
  is_enabled SMALLINT NOT NULL DEFAULT 1,
  CONSTRAINT PK_alert_target PRIMARY KEY (target_id)
);

CREATE TABLE ambari.alert_target_states (
  target_id BIGINT NOT NULL,
  alert_state VARCHAR(255) NOT NULL,
  FOREIGN KEY (target_id) REFERENCES ambari.alert_target(target_id)
);

CREATE TABLE ambari.alert_group_target (
  group_id BIGINT NOT NULL,
  target_id BIGINT NOT NULL,
  CONSTRAINT PK_alert_group_target PRIMARY KEY (group_id, target_id),
  FOREIGN KEY (group_id) REFERENCES ambari.alert_group(group_id),
  FOREIGN KEY (target_id) REFERENCES ambari.alert_target(target_id)
);

CREATE TABLE ambari.alert_grouping (
  definition_id BIGINT NOT NULL,
  group_id BIGINT NOT NULL,
  CONSTRAINT PK_alert_grouping PRIMARY KEY (group_id, definition_id),
  FOREIGN KEY (definition_id) REFERENCES ambari.alert_definition(definition_id),
  FOREIGN KEY (group_id) REFERENCES ambari.alert_group(group_id)
);

CREATE TABLE ambari.alert_notice (
  notification_id BIGINT NOT NULL,
  target_id BIGINT NOT NULL,
  history_id BIGINT NOT NULL,
  notify_state VARCHAR(255) NOT NULL,
  uuid VARCHAR(64) NOT NULL UNIQUE,
  CONSTRAINT PK_alert_notice PRIMARY KEY (notification_id),
  FOREIGN KEY (target_id) REFERENCES ambari.alert_target(target_id),
  FOREIGN KEY (history_id) REFERENCES ambari.alert_history(alert_id)
);

GRANT ALL PRIVILEGES ON TABLE ambari.alert_definition TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_history TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_current TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_group TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_target TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_target_states TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_group_target TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_grouping TO :username;
GRANT ALL PRIVILEGES ON TABLE ambari.alert_notice TO :username;

CREATE INDEX idx_alert_history_def_id on ambari.alert_history(alert_definition_id);
CREATE INDEX idx_alert_history_service on ambari.alert_history(service_name);
CREATE INDEX idx_alert_history_host on ambari.alert_history(host_name);
CREATE INDEX idx_alert_history_time on ambari.alert_history(alert_timestamp);
CREATE INDEX idx_alert_history_state on ambari.alert_history(alert_state);
CREATE INDEX idx_alert_group_name on ambari.alert_group(group_name);
CREATE INDEX idx_alert_notice_state on ambari.alert_notice(notify_state);

---------inserting some data-----------
-- In order for the first ID to be 1, must initialize the ambari_sequences table with a sequence_value of 0.
BEGIN;
INSERT INTO ambari.ambari_sequences (sequence_name, sequence_value) VALUES
  ('cluster_id_seq', 1),
  ('host_id_seq', 0),
  ('user_id_seq', 2),
  ('group_id_seq', 1),
  ('member_id_seq', 1),
  ('host_role_command_id_seq', 1),
  ('configgroup_id_seq', 1),
  ('requestschedule_id_seq', 1),
  ('resourcefilter_id_seq', 1),
  ('viewentity_id_seq', 0),
  ('operation_level_id_seq', 1),
  ('view_instance_id_seq', 1),
  ('resource_type_id_seq', 4),
  ('resource_id_seq', 2),
  ('principal_type_id_seq', 8),
  ('principal_id_seq', 13),
  ('permission_id_seq', 7),
  ('privilege_id_seq', 1),
  ('alert_definition_id_seq', 0),
  ('alert_group_id_seq', 0),
  ('alert_target_id_seq', 0),
  ('alert_history_id_seq', 0),
  ('alert_notice_id_seq', 0),
  ('alert_current_id_seq', 0),
  ('config_id_seq', 1),
  ('repo_version_id_seq', 0),
  ('cluster_version_id_seq', 0),
  ('host_version_id_seq', 0),
  ('service_config_id_seq', 1),
  ('upgrade_id_seq', 0),
  ('upgrade_group_id_seq', 0),
  ('widget_id_seq', 0),
  ('widget_layout_id_seq', 0),
  ('upgrade_item_id_seq', 0),
  ('stack_id_seq', 0),
  ('extension_id_seq', 0),
  ('link_id_seq', 0),
  ('topology_host_info_id_seq', 0),
  ('topology_host_request_id_seq', 0),
  ('topology_host_task_id_seq', 0),
  ('topology_logical_request_id_seq', 0),
  ('topology_logical_task_id_seq', 0),
  ('topology_request_id_seq', 0),
  ('topology_host_group_id_seq', 0),
  ('setting_id_seq', 0),
  ('hostcomponentstate_id_seq', 0),
  ('servicecomponentdesiredstate_id_seq', 0),
  ('servicecomponent_history_id_seq', 0),
  ('blueprint_setting_id_seq', 0),
  ('ambari_operation_history_id_seq', 0),
  ('remote_cluster_id_seq', 0),
  ('remote_cluster_service_id_seq', 0);

INSERT INTO ambari.adminresourcetype (resource_type_id, resource_type_name) VALUES
  (1, 'AMBARI'),
  (2, 'CLUSTER'),
  (3, 'VIEW');

INSERT INTO ambari.adminresource (resource_id, resource_type_id) VALUES
  (1, 1);

INSERT INTO ambari.adminprincipaltype (principal_type_id, principal_type_name) VALUES
  (1, 'USER'),
  (2, 'GROUP'),
  (3, 'ALL.CLUSTER.ADMINISTRATOR'),
  (4, 'ALL.CLUSTER.OPERATOR'),
  (5, 'ALL.CLUSTER.USER'),
  (6, 'ALL.SERVICE.ADMINISTRATOR'),
  (7, 'ALL.SERVICE.OPERATOR'),
  (8, 'ROLE');

INSERT INTO ambari.adminprincipal (principal_id, principal_type_id) VALUES
  (1, 1),
  (2, 3),
  (3, 4),
  (4, 5),
  (5, 6),
  (6, 7),
  (7, 8),
  (8, 8),
  (9, 8),
  (10, 8),
  (11, 8),
  (12, 8),
  (13, 8);

INSERT INTO ambari.Users (user_id, principal_id, user_name, user_password)
  SELECT 1, 1, 'admin', '538916f8943ec225d97a9a86a2c6ec0818c1cd400e09e03b660fdaaec4af29ddbb6f2b1033b81b00';

INSERT INTO ambari.adminpermission(permission_id, permission_name, resource_type_id, permission_label, principal_id, sort_order)
  SELECT 1, 'AMBARI.ADMINISTRATOR', 1, 'Ambari Administrator', 7, 1 UNION ALL
  SELECT 2, 'CLUSTER.USER', 2, 'Cluster User', 8, 6 UNION ALL
  SELECT 3, 'CLUSTER.ADMINISTRATOR', 2, 'Cluster Administrator', 9, 2 UNION ALL
  SELECT 4, 'VIEW.USER', 3, 'View User', 10, 7 UNION ALL
  SELECT 5, 'CLUSTER.OPERATOR', 2, 'Cluster Operator', 11, 3 UNION ALL
  SELECT 6, 'SERVICE.ADMINISTRATOR', 2, 'Service Administrator', 12, 4 UNION ALL
  SELECT 7, 'SERVICE.OPERATOR', 2, 'Service Operator', 13, 5;

INSERT INTO ambari.roleauthorization(authorization_id, authorization_name)
  SELECT 'VIEW.USE', 'Use View' UNION ALL
  SELECT 'SERVICE.VIEW_METRICS', 'View metrics' UNION ALL
  SELECT 'SERVICE.VIEW_STATUS_INFO', 'View status information' UNION ALL
  SELECT 'SERVICE.VIEW_CONFIGS', 'View configurations' UNION ALL
  SELECT 'SERVICE.COMPARE_CONFIGS', 'Compare configurations' UNION ALL
  SELECT 'SERVICE.VIEW_ALERTS', 'View service-level alerts' UNION ALL
  SELECT 'SERVICE.START_STOP', 'Start/Stop/Restart Service' UNION ALL
  SELECT 'SERVICE.DECOMMISSION_RECOMMISSION', 'Decommission/recommission' UNION ALL
  SELECT 'SERVICE.RUN_SERVICE_CHECK', 'Run service checks' UNION ALL
  SELECT 'SERVICE.TOGGLE_MAINTENANCE', 'Turn on/off maintenance mode' UNION ALL
  SELECT 'SERVICE.RUN_CUSTOM_COMMAND', 'Perform service-specific tasks' UNION ALL
  SELECT 'SERVICE.MODIFY_CONFIGS', 'Modify configurations' UNION ALL
  SELECT 'SERVICE.MANAGE_CONFIG_GROUPS', 'Manage configuration groups' UNION ALL
  SELECT 'SERVICE.MANAGE_ALERTS', 'Manage service-level alerts' UNION ALL
  SELECT 'SERVICE.MOVE', 'Move to another host' UNION ALL
  SELECT 'SERVICE.ENABLE_HA', 'Enable HA' UNION ALL
  SELECT 'SERVICE.TOGGLE_ALERTS', 'Enable/disable service-level alerts' UNION ALL
  SELECT 'SERVICE.ADD_DELETE_SERVICES', 'Add/delete services' UNION ALL
  SELECT 'SERVICE.VIEW_OPERATIONAL_LOGS', 'View service operational logs' UNION ALL
  SELECT 'SERVICE.SET_SERVICE_USERS_GROUPS', 'Set service users and groups' UNION ALL
  SELECT 'HOST.VIEW_METRICS', 'View metrics' UNION ALL
  SELECT 'HOST.VIEW_STATUS_INFO', 'View status information' UNION ALL
  SELECT 'HOST.VIEW_CONFIGS', 'View configuration' UNION ALL
  SELECT 'HOST.TOGGLE_MAINTENANCE', 'Turn on/off maintenance mode' UNION ALL
  SELECT 'HOST.ADD_DELETE_COMPONENTS', 'Install components' UNION ALL
  SELECT 'HOST.ADD_DELETE_HOSTS', 'Add/Delete hosts' UNION ALL
  SELECT 'CLUSTER.VIEW_METRICS', 'View metrics' UNION ALL
  SELECT 'CLUSTER.VIEW_STATUS_INFO', 'View status information' UNION ALL
  SELECT 'CLUSTER.VIEW_CONFIGS', 'View configuration' UNION ALL
  SELECT 'CLUSTER.VIEW_STACK_DETAILS', 'View stack version details' UNION ALL
  SELECT 'CLUSTER.VIEW_ALERTS', 'View cluster-level alerts' UNION ALL
  SELECT 'CLUSTER.MANAGE_CREDENTIALS', 'Manage external credentials' UNION ALL
  SELECT 'CLUSTER.MODIFY_CONFIGS', 'Modify cluster configurations' UNION ALL
  SELECT 'CLUSTER.MANAGE_ALERTS', 'Manage cluster-level alerts' UNION ALL
  SELECT 'CLUSTER.MANAGE_USER_PERSISTED_DATA', 'Manage cluster-level user persisted data' UNION ALL
  SELECT 'CLUSTER.TOGGLE_ALERTS', 'Enable/disable cluster-level alerts' UNION ALL
  SELECT 'CLUSTER.MANAGE_CONFIG_GROUPS', 'Manage cluster config groups' UNION ALL
  SELECT 'CLUSTER.TOGGLE_KERBEROS', 'Enable/disable Kerberos' UNION ALL
  SELECT 'CLUSTER.UPGRADE_DOWNGRADE_STACK', 'Upgrade/downgrade stack' UNION ALL
  SELECT 'AMBARI.ADD_DELETE_CLUSTERS', 'Create new clusters' UNION ALL
  SELECT 'AMBARI.RENAME_CLUSTER', 'Rename clusters' UNION ALL
  SELECT 'AMBARI.MANAGE_SETTINGS', 'Manage settings' UNION ALL
  SELECT 'AMBARI.MANAGE_USERS', 'Manage users' UNION ALL
  SELECT 'AMBARI.MANAGE_GROUPS', 'Manage groups' UNION ALL
  SELECT 'AMBARI.MANAGE_VIEWS', 'Manage Ambari Views' UNION ALL
  SELECT 'AMBARI.ASSIGN_ROLES', 'Assign roles' UNION ALL
  SELECT 'AMBARI.MANAGE_STACK_VERSIONS', 'Manage stack versions' UNION ALL
  SELECT 'AMBARI.EDIT_STACK_REPOS', 'Edit stack repository URLs';

-- Set authorizations for View User role
INSERT INTO ambari.permission_roleauthorization(permission_id, authorization_id)
  SELECT permission_id, 'VIEW.USE' FROM ambari.adminpermission WHERE permission_name='VIEW.USER';

-- Set authorizations for Cluster User role
INSERT INTO ambari.permission_roleauthorization(permission_id, authorization_id)
  SELECT permission_id, 'SERVICE.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'SERVICE.COMPARE_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'HOST.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'HOST.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'HOST.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STACK_DETAILS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_USER_PERSISTED_DATA' FROM ambari.adminpermission WHERE permission_name='CLUSTER.USER';

-- Set authorizations for Service Operator role
INSERT INTO ambari.permission_roleauthorization(permission_id, authorization_id)
  SELECT permission_id, 'SERVICE.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.COMPARE_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.START_STOP' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.DECOMMISSION_RECOMMISSION' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_SERVICE_CHECK' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_CUSTOM_COMMAND' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STACK_DETAILS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_USER_PERSISTED_DATA' FROM ambari.adminpermission WHERE permission_name='SERVICE.OPERATOR';

-- Set authorizations for Service Administrator role
INSERT INTO ambari.permission_roleauthorization(permission_id, authorization_id)
  SELECT permission_id, 'SERVICE.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.COMPARE_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.START_STOP' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.DECOMMISSION_RECOMMISSION' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_SERVICE_CHECK' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_CUSTOM_COMMAND' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MODIFY_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_OPERATIONAL_LOGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STACK_DETAILS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_USER_PERSISTED_DATA' FROM ambari.adminpermission WHERE permission_name='SERVICE.ADMINISTRATOR';

-- Set authorizations for Cluster Operator role
INSERT INTO ambari.permission_roleauthorization(permission_id, authorization_id)
  SELECT permission_id, 'SERVICE.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.COMPARE_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.START_STOP' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.DECOMMISSION_RECOMMISSION' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_SERVICE_CHECK' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_CUSTOM_COMMAND' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MODIFY_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MOVE' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.ENABLE_HA' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_OPERATIONAL_LOGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.ADD_DELETE_COMPONENTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'HOST.ADD_DELETE_HOSTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STACK_DETAILS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_CREDENTIALS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_USER_PERSISTED_DATA' FROM ambari.adminpermission WHERE permission_name='CLUSTER.OPERATOR';

-- Set authorizations for Cluster Administrator role
INSERT INTO ambari.permission_roleauthorization(permission_id, authorization_id)
  SELECT permission_id, 'SERVICE.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.COMPARE_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.START_STOP' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.DECOMMISSION_RECOMMISSION' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_SERVICE_CHECK' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_CUSTOM_COMMAND' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MODIFY_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MANAGE_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MOVE' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.ENABLE_HA' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.TOGGLE_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.ADD_DELETE_SERVICES' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_OPERATIONAL_LOGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.SET_SERVICE_USERS_GROUPS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.ADD_DELETE_COMPONENTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.ADD_DELETE_HOSTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STACK_DETAILS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_CREDENTIALS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MODIFY_CONFIGS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.TOGGLE_ALERTS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.TOGGLE_KERBEROS' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.UPGRADE_DOWNGRADE_STACK' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_USER_PERSISTED_DATA' FROM ambari.adminpermission WHERE permission_name='CLUSTER.ADMINISTRATOR';

-- Set authorizations for Administrator role
INSERT INTO ambari.permission_roleauthorization(permission_id, authorization_id)
  SELECT permission_id, 'VIEW.USE' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.COMPARE_CONFIGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.START_STOP' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.DECOMMISSION_RECOMMISSION' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_SERVICE_CHECK' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.RUN_CUSTOM_COMMAND' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MODIFY_CONFIGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MANAGE_ALERTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.MOVE' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.ENABLE_HA' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.TOGGLE_ALERTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.ADD_DELETE_SERVICES' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.VIEW_OPERATIONAL_LOGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'SERVICE.SET_SERVICE_USERS_GROUPS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.TOGGLE_MAINTENANCE' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.ADD_DELETE_COMPONENTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'HOST.ADD_DELETE_HOSTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_METRICS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STATUS_INFO' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_CONFIGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_STACK_DETAILS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.VIEW_ALERTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_CREDENTIALS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MODIFY_CONFIGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_ALERTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_CONFIG_GROUPS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.TOGGLE_ALERTS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.TOGGLE_KERBEROS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.UPGRADE_DOWNGRADE_STACK' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'CLUSTER.MANAGE_USER_PERSISTED_DATA' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.ADD_DELETE_CLUSTERS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.RENAME_CLUSTER' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.MANAGE_SETTINGS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.MANAGE_USERS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.MANAGE_GROUPS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.MANAGE_VIEWS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.ASSIGN_ROLES' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.MANAGE_STACK_VERSIONS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR' UNION ALL
  SELECT permission_id, 'AMBARI.EDIT_STACK_REPOS' FROM ambari.adminpermission WHERE permission_name='AMBARI.ADMINISTRATOR';


INSERT INTO ambari.adminprivilege (privilege_id, permission_id, resource_id, principal_id) VALUES
  (1, 1, 1, 1);

INSERT INTO ambari.metainfo (metainfo_key, metainfo_value) VALUES
  ('version', '2.4.0');
COMMIT;

-- Quartz tables

CREATE TABLE ambari.qrtz_job_details
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  JOB_NAME  VARCHAR(200) NOT NULL,
  JOB_GROUP VARCHAR(200) NOT NULL,
  DESCRIPTION VARCHAR(250) NULL,
  JOB_CLASS_NAME   VARCHAR(250) NOT NULL,
  IS_DURABLE BOOL NOT NULL,
  IS_NONCONCURRENT BOOL NOT NULL,
  IS_UPDATE_DATA BOOL NOT NULL,
  REQUESTS_RECOVERY BOOL NOT NULL,
  JOB_DATA BYTEA NULL,
  PRIMARY KEY (SCHED_NAME,JOB_NAME,JOB_GROUP)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_job_details TO :username;

CREATE TABLE ambari.qrtz_triggers
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  TRIGGER_NAME VARCHAR(200) NOT NULL,
  TRIGGER_GROUP VARCHAR(200) NOT NULL,
  JOB_NAME  VARCHAR(200) NOT NULL,
  JOB_GROUP VARCHAR(200) NOT NULL,
  DESCRIPTION VARCHAR(250) NULL,
  NEXT_FIRE_TIME BIGINT NULL,
  PREV_FIRE_TIME BIGINT NULL,
  PRIORITY INTEGER NULL,
  TRIGGER_STATE VARCHAR(16) NOT NULL,
  TRIGGER_TYPE VARCHAR(8) NOT NULL,
  START_TIME BIGINT NOT NULL,
  END_TIME BIGINT NULL,
  CALENDAR_NAME VARCHAR(200) NULL,
  MISFIRE_INSTR SMALLINT NULL,
  JOB_DATA BYTEA NULL,
  PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
  FOREIGN KEY (SCHED_NAME,JOB_NAME,JOB_GROUP)
  REFERENCES ambari.QRTZ_JOB_DETAILS(SCHED_NAME,JOB_NAME,JOB_GROUP)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_triggers TO :username;

CREATE TABLE ambari.qrtz_simple_triggers
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  TRIGGER_NAME VARCHAR(200) NOT NULL,
  TRIGGER_GROUP VARCHAR(200) NOT NULL,
  REPEAT_COUNT BIGINT NOT NULL,
  REPEAT_INTERVAL BIGINT NOT NULL,
  TIMES_TRIGGERED BIGINT NOT NULL,
  PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
  FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
  REFERENCES ambari.QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_simple_triggers TO :username;

CREATE TABLE ambari.qrtz_cron_triggers
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  TRIGGER_NAME VARCHAR(200) NOT NULL,
  TRIGGER_GROUP VARCHAR(200) NOT NULL,
  CRON_EXPRESSION VARCHAR(120) NOT NULL,
  TIME_ZONE_ID VARCHAR(80),
  PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
  FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
  REFERENCES ambari.QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_cron_triggers TO :username;

CREATE TABLE ambari.qrtz_simprop_triggers
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  TRIGGER_NAME VARCHAR(200) NOT NULL,
  TRIGGER_GROUP VARCHAR(200) NOT NULL,
  STR_PROP_1 VARCHAR(512) NULL,
  STR_PROP_2 VARCHAR(512) NULL,
  STR_PROP_3 VARCHAR(512) NULL,
  INT_PROP_1 INT NULL,
  INT_PROP_2 INT NULL,
  LONG_PROP_1 BIGINT NULL,
  LONG_PROP_2 BIGINT NULL,
  DEC_PROP_1 NUMERIC(13,4) NULL,
  DEC_PROP_2 NUMERIC(13,4) NULL,
  BOOL_PROP_1 BOOL NULL,
  BOOL_PROP_2 BOOL NULL,
  PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
  FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
  REFERENCES ambari.QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_simprop_triggers TO :username;

CREATE TABLE ambari.qrtz_blob_triggers
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  TRIGGER_NAME VARCHAR(200) NOT NULL,
  TRIGGER_GROUP VARCHAR(200) NOT NULL,
  BLOB_DATA BYTEA NULL,
  PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
  FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
  REFERENCES ambari.QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_blob_triggers TO :username;

CREATE TABLE ambari.qrtz_calendars
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  CALENDAR_NAME  VARCHAR(200) NOT NULL,
  CALENDAR BYTEA NOT NULL,
  PRIMARY KEY (SCHED_NAME,CALENDAR_NAME)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_calendars TO :username;


CREATE TABLE ambari.qrtz_paused_trigger_grps
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  TRIGGER_GROUP  VARCHAR(200) NOT NULL,
  PRIMARY KEY (SCHED_NAME,TRIGGER_GROUP)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_paused_trigger_grps TO :username;

CREATE TABLE ambari.qrtz_fired_triggers
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  ENTRY_ID VARCHAR(95) NOT NULL,
  TRIGGER_NAME VARCHAR(200) NOT NULL,
  TRIGGER_GROUP VARCHAR(200) NOT NULL,
  INSTANCE_NAME VARCHAR(200) NOT NULL,
  FIRED_TIME BIGINT NOT NULL,
  SCHED_TIME BIGINT NOT NULL,
  PRIORITY INTEGER NOT NULL,
  STATE VARCHAR(16) NOT NULL,
  JOB_NAME VARCHAR(200) NULL,
  JOB_GROUP VARCHAR(200) NULL,
  IS_NONCONCURRENT BOOL NULL,
  REQUESTS_RECOVERY BOOL NULL,
  PRIMARY KEY (SCHED_NAME,ENTRY_ID)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_fired_triggers TO :username;

CREATE TABLE ambari.qrtz_scheduler_state
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  INSTANCE_NAME VARCHAR(200) NOT NULL,
  LAST_CHECKIN_TIME BIGINT NOT NULL,
  CHECKIN_INTERVAL BIGINT NOT NULL,
  PRIMARY KEY (SCHED_NAME,INSTANCE_NAME)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_scheduler_state TO :username;

CREATE TABLE ambari.qrtz_locks
(
  SCHED_NAME VARCHAR(120) NOT NULL,
  LOCK_NAME  VARCHAR(40) NOT NULL,
  PRIMARY KEY (SCHED_NAME,LOCK_NAME)
);
GRANT ALL PRIVILEGES ON TABLE ambari.qrtz_locks TO :username;

create index idx_qrtz_j_req_recovery on ambari.qrtz_job_details(SCHED_NAME,REQUESTS_RECOVERY);
create index idx_qrtz_j_grp on ambari.qrtz_job_details(SCHED_NAME,JOB_GROUP);

create index idx_qrtz_t_j on ambari.qrtz_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP);
create index idx_qrtz_t_jg on ambari.qrtz_triggers(SCHED_NAME,JOB_GROUP);
create index idx_qrtz_t_c on ambari.qrtz_triggers(SCHED_NAME,CALENDAR_NAME);
create index idx_qrtz_t_g on ambari.qrtz_triggers(SCHED_NAME,TRIGGER_GROUP);
create index idx_qrtz_t_state on ambari.qrtz_triggers(SCHED_NAME,TRIGGER_STATE);
create index idx_qrtz_t_n_state on ambari.qrtz_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_STATE);
create index idx_qrtz_t_n_g_state on ambari.qrtz_triggers(SCHED_NAME,TRIGGER_GROUP,TRIGGER_STATE);
create index idx_qrtz_t_next_fire_time on ambari.qrtz_triggers(SCHED_NAME,NEXT_FIRE_TIME);
create index idx_qrtz_t_nft_st on ambari.qrtz_triggers(SCHED_NAME,TRIGGER_STATE,NEXT_FIRE_TIME);
create index idx_qrtz_t_nft_misfire on ambari.qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME);
create index idx_qrtz_t_nft_st_misfire on ambari.qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_STATE);
create index idx_qrtz_t_nft_st_misfire_grp on ambari.qrtz_triggers(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_GROUP,TRIGGER_STATE);

create index idx_qrtz_ft_trig_inst_name on ambari.qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME);
create index idx_qrtz_ft_inst_job_req_rcvry on ambari.qrtz_fired_triggers(SCHED_NAME,INSTANCE_NAME,REQUESTS_RECOVERY);
create index idx_qrtz_ft_j_g on ambari.qrtz_fired_triggers(SCHED_NAME,JOB_NAME,JOB_GROUP);
create index idx_qrtz_ft_jg on ambari.qrtz_fired_triggers(SCHED_NAME,JOB_GROUP);
create index idx_qrtz_ft_t_g on ambari.qrtz_fired_triggers(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP);
create index idx_qrtz_ft_tg on ambari.qrtz_fired_triggers(SCHED_NAME,TRIGGER_GROUP);
