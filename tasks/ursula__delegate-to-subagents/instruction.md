This task has two independent parts. Give each part to its own subagent: use your agent (task) tool to start one subagent per part, and tell each one everything it needs to work on its own. Start both before waiting on either, if your tools allow it. Don't do either part yourself. Once both subagents have reported back, check their answers and make sure both files are written.

**Part 1.** The files in `/app/logs` are application logs. Each line is a timestamp, a level (`INFO`, `WARN` or `ERROR`) and a message. Count the lines, across all the files, whose level is `ERROR`, and write that count to `/app/answers/errors.txt`.

**Part 2.** `/app/data/sales.csv` lists sales, one per row, with an `amount` column. Write the total of the amounts, with two decimals, to `/app/answers/total.txt`.

Each answer file should hold only the number.
