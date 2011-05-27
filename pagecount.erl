-module(pagecount).

-export([out/1]).



-import(lists, [map/2, foldl/3, reverse/1]).

-include("pagecount.hrl").

%-define(STARTCOUNT, [5966, {2010,5,11}]).
-define(STARTCOUNT, {<<"13994">>, <<"2011-02-01">>}).

-define(QUERY0,
"select
MAX(page_count_count) as day_max, page_count_pdate
from page_count
group by page_count_pdate order by page_count_pdate;"
).

-define(DAY_COUNT_QUERY,
"select MAX(page_count_count)-MIN(page_count_count)+1 as day_count, page_count_pdate
from page_count
group by page_count_pdate order by page_count_pdate;"
).

-define(MAX_PAGE_COUNT_QUERY, "select max(page_count_count) from page_count;").

out(_A) ->
	Rows=do_query(?DAY_COUNT_QUERY),
	Headers=["Page<br>Count", "Date"],
	{ehtml,
		[
		{head, [],
			[
			meta() ++
			style()
        	]
		},
		{body, [],
			{table, [], 
				[[
				{tr, [],
          			[
          			{th, [], X} || X <- Headers
         			]
         		} | d(Rows)] ++
				{tr, [],
          			[
         			{th, [{colspan,"3"}], integer_to_list(get_tot(Rows)) ++ " - Total Pages Printed<br>(Cartridge)"}
         			]
         		}] ++
				{tr, [],
          			[
         			{th, [{colspan,"3"}], tpp() ++ " - Total Pages Printed<br>(Printer)"}
         			]
         		}
			}
		}
		]
	}.

tpp() ->
	[{Tot}] = do_query(?MAX_PAGE_COUNT_QUERY),
	binary_to_list(Tot).

do_query(Sp) ->
	{ok, Db} = pgsql:connect(?HOST, ?USERNAME, ?PASSWORD, [{database, ?DB}]),
	{_,_,Res}=pgsql:squery(Db, Sp),
	pgsql:close(Db),
	Res.
	
get_tot(Rows) ->
	lists:foldl(fun(X, Sum) -> X + Sum end, 0, mk_count_lst(Rows)).

d([H|T]) ->
	[mk_row(H) | d(T)];
d([]) -> [].
	
mk_row(First) ->
	{FcountB,FdateB} = First,
	Fcount=list_to_integer(binary_to_list(FcountB)),
	Fdate=binary_to_list(FdateB),
	{tr, [],
		[{td, [{style, "text-align:right"}], massage(Fcount)}, {td, [], massage(Fdate)}]
	}.

mk_count_lst([H|T]) ->
	[mk_count_lst_o(H) | mk_count_lst(T)];
mk_count_lst([]) -> [].
	
mk_count_lst_o(First) ->
	{FcountB,_} = First,
	Fcount=list_to_integer(binary_to_list(FcountB)),
	Fcount.
	
massage({A,B,C}) ->
	case A > 23 of
		true ->
			io_lib:format("~p-~2..0B-~2..0B", [A,B,C]);
		false ->
			io_lib:format("~2..0B:~2..0B:~2..0B", [A,B,C])
	end;

massage(A) when is_integer(A) ->
	io_lib:format("~p", [A]);
	
massage(A) ->
	io_lib:format("~s", [A]).

%a2l(A) when is_atom(A) -> atom_to_list(A);
%a2l(L) when is_list(L) -> L.

meta() ->
    [{pre_html, 
      "<META HTTP-EQUIV=\"EXPIRES\" CONTENT=\""
      "Sun, 16 Oct 2004 11:12:01 GMT\">"}].
      
style() ->
    [{style, [{type, "text/css"}],
      [{pre_html,
        ["\nbody {background-color:black;}\n",
         "table {border-collapse: collapse; border: solid black 1px; background-color:grey;}\n"
         "p {padding: 5px; font-weight: bold;}\n"
         "input[type=text] {vertical-align: bottom; width: 100%; font-size: 80%;}\n"
         "input[type=checkbox] {vertical-align: top; font-size: 80%;}\n"
         "span.attribute {vertical-align: top; font-size: 80%;}\n"
         "th {padding: 5px; border: solid black 1px;}\n"
         "td {padding: 5px; border: solid black 1px;}\n"
        ]}]}].
