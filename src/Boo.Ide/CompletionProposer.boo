namespace Boo.Ide

import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

import Boo.Adt
import Boo.Lang.PatternMatching

data CompletionProposal(Entity as IEntity)

static class CompletionProposer:
	
	def ForExpression(expression as Expression):
		match expression:
			case MemberReferenceExpression(Target: Expression(ExpressionType)) and ExpressionType is not null:
				for member in AccessibleMembersOf(ExpressionType):
					yield CompletionProposal(member)
			otherwise:
				pass
				
	def AccessibleMembersOf(type as IType):
		currentType = type
		while currentType is not null:
			for member in currentType.GetMembers():
				match member:
					case IConstructor():
						continue
					case IAccessibleMember(IsPublic, IsStatic):
						if IsPublic and not IsStatic:
							yield member
					otherwise:
						continue
			currentType = currentType.BaseType

