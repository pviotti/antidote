%% -------------------------------------------------------------------
%%
%% Copyright (c) 2014 SyncFree Consortium.  All Rights Reserved.
%%
% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(systematic_tests_SUITE).

-compile({parse_transform, lager_transform}).

%% common_test callbacks
-export([
    init_per_suite/1,
    end_per_suite/1,
    init_per_testcase/2,
    end_per_testcase/2,
    all/0]).

%% tests
-export([poco_test/1]).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("kernel/include/inet.hrl").

-define(ADDRESS, "localhost").

-define(PORT, 10017).

init_per_suite(Config) ->
    test_utils:at_init_testsuite(),
    Clusters = test_utils:set_up_clusters_common(Config),
    Nodes = hd(Clusters),
    [{nodes, Nodes}|Config].

end_per_suite(Config) ->
    Config.

init_per_testcase(_Case, Config) ->
    Config.

end_per_testcase(_, _) ->
    ok.

all() -> [poco_test].

poco_test(Config) ->
    Clusters = proplists:get_value(clusters, Config),
    [Node1, Node2 | _Nodes] =  [ hd(Cluster)|| Cluster <- Clusters ],

    Bucket = poco_bucket,
    Type = antidote_crdt_lwwreg,


    %% Define two objects
    Object1 = {key1, Type, Bucket},
    Object2 = {key2, Type, Bucket},

    %% Assign 1 to the first object at the first replica
    Response1=rpc:call(Node1, antidote, update_objects, [ignore, [], [{Object1, assign, 1}]]),
    ?assertMatch({ok, _}, Response1),
    %% Assign 2 to the first object at the first replica
    Response2=rpc:call(Node1, antidote, update_objects, [ignore, [], [{Object1, assign, 2}]]),
    ?assertMatch({ok, _}, Response2),

    %% Assign 3 to the second object at the first replica
    Response3=rpc:call(Node1, antidote, update_objects, [ignore, [], [{Object2, assign, 3}]]),
    ?assertMatch({ok, _}, Response3),

    %% Read from another replica, both objects.
    ReadObject2Result = rpc:call(Node2, antidote, read_objects, [ignore, [], [Object2]]),
    ReadObject1Result = rpc:call(Node2, antidote, read_objects, [ignore, [], [Object1]]),

    {ok, [Object2Val], _} = ReadObject2Result,
    {ok, [Object1Val], _} = ReadObject1Result,

    case Object2Val of
        3 ->
            ct:print("Value of object 2 is 3, will check that object 1 is 2"),
            ?assertMatch(2, Object1Val),
            ct:print("Correct!");
        _ ->
            ct:print("Value of object 2 is not 3, nothing to do..."),
            continue
    end,
    pass.

