# Review checklist

Adapted from Google's engineering practices guide, "What to look for in a code review" (https://google.github.io/eng-practices/review/reviewer/looking-for.html), with .NET-specific prompts added. Work from top to bottom. The top items matter most.

1. **Does it do what the ticket asked?** Read the ticket or spec first. Is anything missing, or is something there that nobody asked for?
2. **Is it correct?** Walk through the edge cases: empty, null, zero, one, many, duplicate, the wrong user, two requests at the same time.
3. **Security.** Is every input validated? Does it check that *this user* may touch *this record*, not just that someone is logged in? Any secrets in code? SQL built from strings?
4. **Errors.** What happens when the database, an API or a file isn't there? Are exceptions caught and swallowed silently? Any `async void` (except event handlers)?
5. **Data access (EF Core).** Queries inside loops (N+1)? Loading whole tables to filter in memory? A missing `AsNoTracking()` on read-only queries? Do migrations do what the change needs?
6. **Tests.** Do tests cover the behaviors in the ticket, including the failure cases? Would they fail if the code were wrong?
7. **Design.** Is the logic in the right layer (not business rules inside a Blazor component or a controller)? Does it follow how the rest of the codebase does it?
8. **Complexity.** Could a teammate understand it quickly? Is anything over-built "for later"?
9. **Naming and comments.** Do names say what things are? Do comments explain *why*, not *what*?

Write down anything that makes you pause, even if you're not sure. "Not sure" findings are how you learn.
