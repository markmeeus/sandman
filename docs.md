ff alle lua api's  opschrijven
TODO : wil zeggen, luerl encode/decode nog ff na te kijken

luerlmapper:

    "print" > TODO ? voor tables

    # {:ok, [], luerl_state} = :luerl_new.set_table_keys(["cron","start"], {:erl_func, handlers.cron_start}, luerl_state)
    # {:ok, [], luerl_state} = :luerl_new.set_table_keys(["cron","stop"], {:erl_func, handlers.cron_stop}, luerl_state)

    sandman.server.start()  TODO

    sandman.server.get (post put delete path head) TODO

    sandman.http (get post put delete patch head) TODO (response reeds klaar denk ik)
    sandman http.send TODO

    sandman.uri.parse TODO
    sandman.uri.tostring TODO
    sandman.uri.encode TODO
    sandman.uri.decode TODO
    sandman.uri.encodeComponent TODO
    sandman.uri.decodeComponent TODO

    sandman.json.encode OK
    sandman.json.decode OK
