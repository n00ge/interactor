# Fork and Alternative Analysis

**Date:** 2025-10-21

## Summary

**No forks solve our modernization needs.** All examined forks still use OpenStruct. However, there are **modern alternatives** worth considering if you don't need to stay with the interactor gem.

---

## 🔍 Forks Investigation

### Examined Forks
Checked 20+ forks sorted by stars and recent activity:
- **Quitehours/interactor** (updated 2025-07-27)
- **kaspermeyer/interactor** (updated 2025-02-28)
- **unsplash/interactor** (updated 2024-01-16)
- **bigcommerce-labs/interactor** (updated 2024-02-27)
- All others with 0-1 stars

### Result
**❌ ALL forks still use OpenStruct**

```ruby
# Every fork examined still has this:
class Context < OpenStruct
  # ...
end
```

**Conclusion:** No fork has solved the critical modernization issues.

---

## 📝 Relevant Pull Requests & Issues

### PR #213: "Remove use of open struct on context"
- **Author:** internethostage
- **Status:** Closed, NOT merged
- **Created:** 2024-01-12
- **Description:** "Replace openstruct with a funny method_missing approach"
- **Result:** Never merged, no explanation given
- **Branch:** No longer accessible

### PR #149: "BYO Context interactor flavor"
- **Author:** jonstokes
- **Status:** Closed, NOT merged
- **Created:** 2017-07-11
- **Key Points:**
  - Attempted to allow custom context classes
  - Wanted to replace OpenStruct with PORO (Plain Old Ruby Object)
  - Motivation: Performance (OpenStruct is slow) + Contracts/Validation
  - Proposed `context_with CustomContext` DSL
  - Never merged

**Quote from PR #149:**
> "To me, the context object is by far the weakest part of this gem. First, OpenStruct is notoriously slow, and everyone avoids it if they can. A PORO would be way faster. But an even bigger deal is the lack of support for contracts, which most of these actor-type gems have nowadays."

### Issue #67: "A proposal for a non-magical, but stricter context"
- **Status:** Closed
- **Created:** 2014-09-23
- **Proposed:** Declaring context attributes explicitly
- **Never implemented**

**Key Insight:** The maintainers are **aware** of the OpenStruct limitations but have chosen not to address them.

---

## 🚀 Modern Alternatives

### 1. u-case (⭐ 531 stars) - **RECOMMENDED ALTERNATIVE**

**Repository:** https://github.com/serradura/u-case

**Key Features:**
- ✅ **No OpenStruct** - uses `u-attributes` gem for read-only attributes
- ✅ **Modern** - actively maintained (last update: 2025-10-01)
- ✅ **Fast** - includes performance benchmarks showing it's faster than interactor
- ✅ **Ruby 2.2+** support
- ✅ **Explicit attributes** - `attributes :a, :b` instead of magical OpenStruct
- ✅ **Flow composition** - similar to organizers
- ✅ **Type safety** - uses `kind` gem for runtime type checking
- ✅ **ActiveModel validation** support (optional)
- ✅ **Immutable** - promotes data transformation over mutation
- ✅ **No callbacks** - no before/after/around hooks (by design)

**Example:**
```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure result: { message: 'arguments must be numeric' }
    end
  end
end

result = Multiply.call(a: 2, b: 3)
result.success? # true
result[:number] # 6
```

**Philosophy Differences:**
- No magical context object
- Explicit attribute declaration
- No hooks (for better code linearity)
- Built-in result pattern matching
- Performance-focused

**Dependencies:**
- `kind` gem (type system)
- `u-attributes` gem (read-only attributes)
- `activemodel` (optional, for validations)

**Pros:**
- Solves all OpenStruct issues
- Modern Ruby best practices
- Well documented with examples
- Good performance
- Active community

**Cons:**
- Different API (migration required)
- No hooks (if you rely on them)
- More opinionated architecture

---

### 2. dry-transaction (dry-rb ecosystem)

**Repository:** https://github.com/dry-rb/dry-transaction

**Key Features:**
- Part of the dry-rb ecosystem
- Railway-oriented programming
- Step-by-step operations
- No OpenStruct
- Highly composable

**Note:** More complex, heavier framework. Good if you're already using dry-rb.

---

### 3. trailblazer-operation (Trailblazer ecosystem)

**Repository:** https://github.com/trailblazer/trailblazer-operation

**Key Features:**
- Part of Trailblazer framework
- Railway pattern
- Very feature-rich
- Policy support, contracts, etc.

**Note:** Heavy framework. Overkill if you just need service objects.

---

### 4. service_operator (⭐ 1 star)

**Repository:** https://github.com/kortirso/service_operator

**Key Features:**
- Inspired by interactor and dry-transaction
- Lightweight
- Modern approach

**Note:** Very low adoption, not well maintained.

---

### 5. AllSystems (⭐ 10 stars)

**Repository:** https://github.com/CrowdHailer/AllSystems

**Key Features:**
- Simple service objects
- Minimal dependencies

**Note:** Low adoption, last updated 2019.

---

## 📊 Comparison Matrix

| Feature | Interactor | u-case | dry-transaction | Trailblazer |
|---------|-----------|---------|-----------------|-------------|
| **Stars** | 3.3k | 531 | 400+ (dry-rb) | 5.5k |
| **Last Update** | 2025-07 | 2025-10 | 2024 | 2025 |
| **OpenStruct** | ❌ Yes (deprecated) | ✅ No | ✅ No | ✅ No |
| **Ruby Version** | Any (no spec) | >= 2.2 | >= 2.7 | >= 2.5 |
| **Dependencies** | ostruct | kind, u-attributes | dry-* | Many |
| **Complexity** | Low | Low | Medium | High |
| **Learning Curve** | Easy | Easy | Medium | Steep |
| **Hooks** | ✅ Yes | ❌ No | Limited | ✅ Yes |
| **Validation** | ❌ No | ✅ Optional | ✅ Via dry-schema | ✅ Via reform |
| **Performance** | Slow (OpenStruct) | Fast | Fast | Medium |
| **Pattern Matching** | ✅ 3.2.0+ | ✅ Yes | ✅ Yes | ✅ Yes |
| **Community** | Large | Growing | Large | Large |

---

## 💡 Recommendations

### If Staying with Interactor
**We must implement the modernization ourselves** - no forks solve this.

**Priority:**
1. Replace OpenStruct with custom implementation
2. Add Ruby version requirements
3. Modernize gemspec and CI

**Estimated Effort:** 2-3 weeks (as per MODERNIZATION_PLAN.md)

---

### If Considering Migration

#### Migrate to u-case if:
- ✅ You want modern Ruby best practices
- ✅ You care about performance
- ✅ You want explicit contracts/validation
- ✅ You can live without hooks
- ✅ You want active maintenance
- ✅ Migration effort is acceptable

**Migration Complexity:** Medium
- API is similar but not identical
- Need to convert contexts to explicit attributes
- Need to replace hooks with explicit code
- Can be done incrementally

#### Stay with Interactor if:
- ✅ You need hooks (before/after/around)
- ✅ You have a large existing codebase
- ✅ You prefer magical context
- ✅ Migration cost is too high
- ❌ Accept technical debt of OpenStruct

---

## 🎯 Decision Matrix

### Stay with Interactor + Modernize
**Good for:**
- Existing large codebases
- Teams invested in current patterns
- Need backwards compatibility

**Must accept:**
- Modernization effort required
- Potential breaking changes (v4.0)
- Still maintaining our own fork

### Migrate to u-case
**Good for:**
- New projects
- Willing to invest in migration
- Want best modern practices
- Care about performance

**Must accept:**
- Migration effort
- Learning new API
- No hooks

### Use dry-transaction/Trailblazer
**Good for:**
- Already using dry-rb or Trailblazer
- Need heavy validation/contracts
- Complex workflows

**Must accept:**
- Heavier dependencies
- Steeper learning curve

---

## 🔬 Community Sentiment

Based on GitHub issues and PRs:

1. **OpenStruct is widely recognized as a problem**
   - Multiple PRs attempted to fix it (all rejected/closed)
   - Community has been asking for this since 2014

2. **Maintainers have not prioritized this**
   - PR #213 (2024) - closed without comment
   - PR #149 (2017) - closed without merge
   - Issue #67 (2014) - discussed but not implemented

3. **Users have migrated to alternatives**
   - Comments mention u-case and dry-transaction
   - Some maintain private forks

4. **Gem is still popular but stagnating**
   - 3.3k stars, but modernization is slow
   - Latest release addressed OpenStruct by adding dependency (band-aid)

---

## 📈 Download Stats (RubyGems)

- **interactor:** ~10M downloads total, ~100k/month
- **u-case:** ~200k downloads total, ~5k/month
- **dry-transaction:** ~3M downloads (part of dry-rb)

**Insight:** Interactor is still widely used but u-case is growing.

---

## ✅ Final Recommendation

### For This Project

**Proceed with modernization plan:**
1. No forks solve our problems
2. Community has tried and failed to get upstream to fix it
3. We need to do it ourselves
4. Our plan addresses all critical issues

### For Future Projects

**Consider u-case:**
- Modern, well-maintained alternative
- Solves all the problems we're fixing
- Better performance
- Cleaner architecture

### For Large Existing Codebases

**Evaluate migration cost:**
- If low: migrate to u-case
- If high: modernize interactor locally
- Consider gradual migration (use both)

---

## 📚 Resources

- **u-case Documentation:** https://github.com/serradura/u-case
- **u-case Rails Example:** https://github.com/serradura/from-fat-controllers-to-use-cases
- **Interactor Issues:** https://github.com/collectiveidea/interactor/issues
- **PR #213 (OpenStruct removal):** https://github.com/collectiveidea/interactor/pull/213
- **PR #149 (Custom contexts):** https://github.com/collectiveidea/interactor/pull/149

---

## 🎬 Next Steps

1. **Review this analysis** with stakeholders
2. **Decide:** Modernize interactor vs. migrate to u-case
3. **If modernizing:** Execute MODERNIZATION_PLAN.md
4. **If migrating:** Create migration plan for u-case
5. **Consider:** Hybrid approach (new code uses u-case, legacy uses interactor)
