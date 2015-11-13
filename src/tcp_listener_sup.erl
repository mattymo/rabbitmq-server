%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License
%% at http://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and
%% limitations under the License.
%%
%% The Original Code is RabbitMQ.
%%
%% The Initial Developer of the Original Code is GoPivotal, Inc.
%% Copyright (c) 2007-2015 Pivotal Software, Inc.  All rights reserved.
%%

-module(tcp_listener_sup).

-behaviour(supervisor).

-export([start_link/9, start_link/10]).

-export([init/1]).

%%----------------------------------------------------------------------------

-ifdef(use_specs).

-type(mfargs() :: {atom(), atom(), [any()]}).

-spec(start_link/9 ::
        (inet:ip_address(), inet:port_number(), module(), [gen_tcp:listen_option()],
         module(), any(), mfargs(), mfargs(), string()) ->
                           rabbit_types:ok_pid_or_error()).
-spec(start_link/10 ::
        (inet:ip_address(), inet:port_number(), module(), [gen_tcp:listen_option()],
         module(), any(), mfargs(), mfargs(), integer(), string()) ->
                           rabbit_types:ok_pid_or_error()).

-endif.

%%----------------------------------------------------------------------------

start_link(IPAddress, Port, Transport, SocketOpts, ProtoSup, ProtoOpts, OnStartup, OnShutdown,
           Label) ->
    start_link(IPAddress, Port, Transport, SocketOpts, ProtoSup, ProtoOpts, OnStartup, OnShutdown,
               1, Label).

start_link(IPAddress, Port, Transport, SocketOpts, ProtoSup, ProtoOpts, OnStartup, OnShutdown,
           ConcurrentAcceptorCount, Label) ->
    supervisor:start_link(
      ?MODULE, {IPAddress, Port, Transport, SocketOpts, ProtoSup, ProtoOpts, OnStartup, OnShutdown,
                ConcurrentAcceptorCount, Label}).

init({IPAddress, Port, Transport, SocketOpts, ProtoSup, ProtoOpts, OnStartup, OnShutdown,
      ConcurrentAcceptorCount, Label}) ->
    {ok, AckTimeout} = application:get_env(rabbit, ssl_handshake_timeout),
    {ok, {{one_for_all, 10, 10}, [
        ranch:child_spec({acceptor, IPAddress, Port}, ConcurrentAcceptorCount,
            Transport, [{port, Port}, {ip, IPAddress},
                {max_connections, infinity},
                {ack_timeout, AckTimeout},
                {connection_type, supervisor}|SocketOpts],
            ProtoSup, ProtoOpts),
        {tcp_listener, {tcp_listener, start_link,
                        [IPAddress, Port,
                         OnStartup, OnShutdown, Label]},
         transient, 16#ffffffff, worker, [tcp_listener]}]}}.
