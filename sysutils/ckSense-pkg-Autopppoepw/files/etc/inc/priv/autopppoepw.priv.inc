<?php
/*
 * autopppoepw.priv.inc
 *
 * build for cloakSense, derive from the pfSense (https://www.pfsense.org)
 * Copyright (c) 2015-2020 Rubicon Communications, LLC (Netgate)
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

global $priv_list;

$priv_list['page-status-autopppoepw'] = array();
$priv_list['page-status-autopppoepw']['name'] = "WebCfg - Status: Autopppoepw";
$priv_list['page-status-autopppoepw']['descr'] = "Allow access to Autopppoepw package GUI";
$priv_list['page-status-autopppoepw']['match'] = array();
$priv_list['page-status-autopppoepw']['match'][] = "pkg.php?xml=autopppoepw.xml*";
$priv_list['page-status-autopppoepw']['match'][] = "pkg_edit.php?xml=autopppoepw.xml*";
$priv_list['page-status-autopppoepw']['match'][] = "pkg_edit.php?xml=autopppoepwsetting.xml*";

?>
