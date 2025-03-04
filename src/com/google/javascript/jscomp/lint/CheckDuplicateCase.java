/*
 * Copyright 2016 The Closure Compiler Authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.google.javascript.jscomp.lint;

import com.google.javascript.jscomp.AbstractCompiler;
import com.google.javascript.jscomp.CompilerPass;
import com.google.javascript.jscomp.DiagnosticType;
import com.google.javascript.jscomp.NodeTraversal;
import com.google.javascript.jscomp.NodeTraversal.AbstractPostOrderCallback;
import com.google.javascript.rhino.Node;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * Check for duplicate case labels in a switch statement Eg: switch (foo) { case 1: case 1: }
 *
 * <p>This is normally an indication of a programmer error.
 *
 * <p>Inspired by ESLint
 * (https://github.com/eslint/eslint/blob/master/lib/rules/no-duplicate-case.js)
 */
public final class CheckDuplicateCase extends AbstractPostOrderCallback implements CompilerPass {
  public static final DiagnosticType DUPLICATE_CASE =
      DiagnosticType.warning("JSC_DUPLICATE_CASE", "Duplicate case in a switch statement.");

  private final AbstractCompiler compiler;

  public CheckDuplicateCase(AbstractCompiler compiler) {
    this.compiler = compiler;
  }

  @Override
  public void process(Node externs, Node root) {
    NodeTraversal.traverse(compiler, root, this);
  }

  @Override
  public void visit(NodeTraversal t, Node n, Node parent) {
    if (n.isSwitch()) {
      Node switchBody = n.getSecondChild();
      Set<String> cases = new LinkedHashSet<>();
      for (Node curr = switchBody.getFirstChild(); curr != null; curr = curr.getNext()) {
        String source = compiler.toSource(curr.getFirstChild());
        if (!cases.add(source)) {
          t.report(curr, DUPLICATE_CASE);
        }
      }
    }
  }
}
